/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.ballerinalang.test;

import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.projects.BuildOptions;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.JBallerinaBackend;
import io.ballerina.projects.JvmTarget;
import io.ballerina.projects.Module;
import io.ballerina.projects.NullBackend;
import io.ballerina.projects.Package;
import io.ballerina.projects.PackageCompilation;
import io.ballerina.projects.Project;
import io.ballerina.projects.ProjectEnvironmentBuilder;
import io.ballerina.projects.ProjectException;
import io.ballerina.projects.directory.ProjectLoader;
import io.ballerina.projects.directory.SingleFileProject;
import io.ballerina.projects.environment.EnvironmentBuilder;
import io.ballerina.projects.repos.FileSystemCache;
import io.ballerina.projects.util.ProjectConstants;
import io.ballerina.projects.util.ProjectUtils;
import io.ballerina.runtime.api.types.semtype.TypeCheckCacheFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.wso2.ballerinalang.compiler.bir.model.BIRNode;
import org.wso2.ballerinalang.compiler.semantics.model.symbols.BPackageSymbol;
import org.wso2.ballerinalang.compiler.tree.BLangPackage;
import org.wso2.ballerinalang.programfile.CompiledBinaryFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;

import static io.ballerina.projects.util.ProjectConstants.CACHES_DIR_NAME;
import static io.ballerina.projects.util.ProjectConstants.DIST_CACHE_DIRECTORY;

/**
 * Helper to drive test source compilation.
 *
 * @since 2.0.0
 */
public final class BCompileUtil {

    private static final Path TEST_SOURCES_DIRECTORY = Path.of("src/test/resources").toAbsolutePath()
            .normalize();
    private static final Path TEST_BUILD_DIRECTORY = Path.of("build").toAbsolutePath().normalize();

    private static final Logger LOGGER = LoggerFactory.getLogger(BCompileUtil.class);

    private BCompileUtil() {}

    public static Project loadProject(String sourceFilePath) {
        BuildOptions.BuildOptionsBuilder buildOptionsBuilder = BuildOptions.builder();
        return loadProject(sourceFilePath, buildOptionsBuilder.build());
    }

    public static Project loadProject(String sourceFilePath, BuildOptions buildOptions) {
        Path sourcePath = Path.of(sourceFilePath);
        String sourceFileName = sourcePath.getFileName().toString();
        Path sourceRoot = TEST_SOURCES_DIRECTORY.resolve(sourcePath.getParent());

        Path projectPath = Path.of(sourceRoot.toString(), sourceFileName);

        BuildOptions defaultOptions;
        try {
            defaultOptions = BuildOptions.builder()
                    .setOffline(true)
                    .setDumpBirFile(true)
                    .targetDir(String.valueOf(Files.createTempDirectory("ballerina-cache" + System.nanoTime())))
                    .build();
        } catch (IOException e) {
            throw new ProjectException("Failed to create the temporary target directory: " + e.getMessage());
        }

        BuildOptions mergedOptions = buildOptions.acceptTheirs(defaultOptions);
        return ProjectLoader.loadProject(projectPath, mergedOptions);
    }

    public static CompileResult compile(String sourceFilePath) {
        TypeCheckCacheFactory.reset();
        Project project = loadProject(sourceFilePath);

        Package currentPackage = project.currentPackage();
        JBallerinaBackend jBallerinaBackend = jBallerinaBackend(currentPackage);
        if (jBallerinaBackend.diagnosticResult().hasErrors()) {
            return new CompileResult(currentPackage, jBallerinaBackend);
        }

        CompileResult compileResult = new CompileResult(currentPackage, jBallerinaBackend);
        invokeModuleInit(compileResult);
        return compileResult;
    }

    public static CompileResult compileOffline(String sourceFilePath) {
        BuildOptions.BuildOptionsBuilder buildOptionsBuilder = BuildOptions.builder();
        BuildOptions buildOptions = buildOptionsBuilder.setOffline(Boolean.TRUE).build();
        Project project = loadProject(sourceFilePath, buildOptions);

        Package currentPackage = project.currentPackage();
        JBallerinaBackend jBallerinaBackend = jBallerinaBackend(currentPackage);
        if (jBallerinaBackend.diagnosticResult().hasErrors()) {
            return new CompileResult(currentPackage, jBallerinaBackend);
        }

        CompileResult compileResult = new CompileResult(currentPackage, jBallerinaBackend);
        invokeModuleInit(compileResult);
        return compileResult;
    }

    public static PackageSyntaxTreePair compileSemType(String sourceFilePath) {
        Project project = loadProject(sourceFilePath);
        Package currentPackage = project.currentPackage();
        Module module = currentPackage.getDefaultModule();
        DocumentId docId = module.documentIds().iterator().next();
        return new PackageSyntaxTreePair(currentPackage.getCompilation().defaultModuleBLangPackage(),
                module.document(docId).syntaxTree());
    }

    public static BIRCompileResult generateBIR(String sourceFilePath) {
        Project project = loadProject(sourceFilePath);
        NullBackend nullBackend = NullBackend.from(project.currentPackage().getCompilation());
        Package currentPackage = project.currentPackage();
        if (currentPackage.getCompilation().diagnosticResult().hasErrors() || nullBackend.hasErrors()) {
            return null;
        }

        BPackageSymbol bPackageSymbol = currentPackage.getCompilation().defaultModuleBLangPackage().symbol;
        if (bPackageSymbol == null) {
            return null;
        }

        CompiledBinaryFile.BIRPackageFile birPackageFile = bPackageSymbol.birPackageFile;
        if (birPackageFile == null) {
            return null;
        }

        return new BIRCompileResult(bPackageSymbol.bir, birPackageFile.pkgBirBinaryContent);
    }

    public static CompileResult compileWithoutInitInvocation(String sourceFilePath) {
        Project project = loadProject(sourceFilePath);

        Package currentPackage = project.currentPackage();
        JBallerinaBackend jBallerinaBackend = jBallerinaBackend(currentPackage);
        if (jBallerinaBackend.diagnosticResult().hasErrors()) {
            return new CompileResult(currentPackage, jBallerinaBackend);
        }

        return new CompileResult(currentPackage, jBallerinaBackend);
    }

    public static CompileResult compileAndCacheBala(String sourceFilePath) {
        return compileAndCacheBala(sourceFilePath, TEST_BUILD_DIRECTORY.resolve(DIST_CACHE_DIRECTORY));
    }

    public static CompileResult compileAndCacheBala(String sourceFilePath, Path repoPath) {
        return compileAndCacheBala(sourceFilePath, repoPath, getTestProjectEnvironmentBuilder());
    }

    public static CompileResult compileAndCacheBala(String sourceFilePath, Path repoPath,
                                             ProjectEnvironmentBuilder projectEnvironmentBuilder) {
        Path sourcePath = Path.of(sourceFilePath);
        String sourceFileName = sourcePath.getFileName().toString();
        Path sourceRoot = TEST_SOURCES_DIRECTORY.resolve(sourcePath.getParent());
        Path projectPath = Path.of(sourceRoot.toString(), sourceFileName);
        return compileAndCacheBala(projectPath, repoPath, projectEnvironmentBuilder);
    }

    public static CompileResult compileAndCacheBala(Path projectPath, Path repoPath,
                                                    ProjectEnvironmentBuilder projectEnvironmentBuilder) {
        BuildOptions defaultOptions = BuildOptions.builder().setOffline(true).setDumpBirFile(true).build();
        Project project = ProjectLoader.loadProject(projectPath, projectEnvironmentBuilder, defaultOptions);

        if (isSingleFileProject(project)) {
            throw new RuntimeException("single file project is given for compilation at " + project.sourceRoot());
        }

        Package currentPackage = project.currentPackage();
        JBallerinaBackend jBallerinaBackend = jBallerinaBackend(currentPackage);
        if (jBallerinaBackend.diagnosticResult().hasErrors()) {
            return new CompileResult(currentPackage, jBallerinaBackend);
        }

        Path balaCachePath = balaCachePath(currentPackage.packageOrg().toString(),
                currentPackage.packageName().toString(), currentPackage.packageVersion().toString(), repoPath);
        jBallerinaBackend.emit(JBallerinaBackend.OutputType.BALA, balaCachePath);
        Path balaFilePath;
        try (Stream<Path> paths = Files.list(balaCachePath)) {
            balaFilePath = paths.filter(path ->
                    path.toString().endsWith(ProjectConstants.BLANG_COMPILED_PKG_BINARY_EXT)).findAny().orElseThrow();
            String platform = getPlatformFromBala(balaFilePath.getFileName().toString(),
                    currentPackage.packageName().toString(), currentPackage.packageVersion().toString());
            if (Files.isDirectory(balaCachePath.resolve(platform))) {
                ProjectUtils.deleteDirectory(balaCachePath.resolve(platform));
            }
            ProjectUtils.extractBala(balaFilePath, balaCachePath.resolve(platform));
            Files.delete(balaFilePath);
        } catch (IOException e) {
            throw new RuntimeException("bala extraction failed " + project.sourceRoot() + ". ", e);
        }

        CompileResult compileResult = new CompileResult(currentPackage, jBallerinaBackend);
        invokeModuleInit(compileResult);
        return compileResult;
    }

    private static JBallerinaBackend jBallerinaBackend(Package currentPackage) {
        PackageCompilation packageCompilation = currentPackage.getCompilation();
        if (packageCompilation.diagnosticResult().errorCount() > 0) {
            LOGGER.error("compilation failed with errors: " + currentPackage.project().sourceRoot());
        }
        return JBallerinaBackend.from(packageCompilation, JvmTarget.JAVA_21);
    }

    /**
     * Copy the given bala to the distribution repository.
     *
     * @param srcPath Path of the source bala.
     * @param org     organization name
     * @param pkgName package name
     * @param version Bala version
     * @throws IOException is thrown if the file copy failed
     */
    public static void copyBalaToDistRepository(Path srcPath,
                                                String org,
                                                String pkgName,
                                                String version) throws IOException {
        Path targetPath = balaCachePath(org, pkgName, version, TEST_BUILD_DIRECTORY.resolve(DIST_CACHE_DIRECTORY))
                .resolve("any");
        if (Files.isDirectory(targetPath)) {
            ProjectUtils.deleteDirectory(targetPath);
        }
        ProjectUtils.extractBala(srcPath, targetPath);
    }

    public static void copyBalaToExtractedDist(Path srcPath, String org, String pkgName, String version,
                                               Path tempDistPath) throws IOException {
        Path targetPath = balaCachePath(org, pkgName, version, tempDistPath).resolve("any");
        if (Files.isDirectory(targetPath)) {
            ProjectUtils.deleteDirectory(targetPath);
        }
        ProjectUtils.extractBala(srcPath, targetPath);
    }

    public static ProjectEnvironmentBuilder getTestProjectEnvironmentBuilder() {
        ProjectEnvironmentBuilder environmentBuilder = ProjectEnvironmentBuilder.getBuilder(
                EnvironmentBuilder.buildDefault());
        return environmentBuilder.addCompilationCacheFactory(TestCompilationCache::from);
    }

    private static void invokeModuleInit(CompileResult compileResult) {
        if (compileResult.getErrorCount() != 0) {
            return;
        }

        try {
            BRunUtil.runInit(compileResult);
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("error while invoking init method of " + compileResult.projectSourceRoot(), e);
        }
    }

    private static boolean isSingleFileProject(Project project) {
        return project instanceof SingleFileProject;
    }

    private static Path balaCachePath(String org,
                                      String pkgName,
                                      String version,
                                      Path repoPath) {
        try {
            Path balaDirPath = repoPath.resolve("bala")
                    .resolve(org)
                    .resolve(pkgName)
                    .resolve(version);
            Files.createDirectories(balaDirPath);
            return balaDirPath;
        } catch (IOException e) {
            throw new RuntimeException("error while creating the bala distribution cache directory at " +
                    TEST_BUILD_DIRECTORY, e);
        }
    }

    /**
     * Compilation cache that dumps bir and jars inside the build directory.
     */
    private static class TestCompilationCache extends FileSystemCache {

        private TestCompilationCache(Project project, Path cacheDirPath) {
            super(project, cacheDirPath.resolve(CACHES_DIR_NAME));
        }

        private static TestCompilationCache from(Project project) {
            Path testCompilationCachePath = TEST_BUILD_DIRECTORY.resolve(DIST_CACHE_DIRECTORY);
            return new TestCompilationCache(project, testCompilationCachePath);
        }
    }

    /**
     * Class to hold both expected and actual compile result of BIR.
     */
    public static class BIRCompileResult {

        private final BIRNode.BIRPackage expectedBIR;
        private final byte[] actualBIRBinary;

        BIRCompileResult(BIRNode.BIRPackage expectedBIR, byte[] actualBIRBinary) {
            this.expectedBIR = expectedBIR;
            this.actualBIRBinary = actualBIRBinary;
        }

        public BIRNode.BIRPackage getExpectedBIR() {
            return expectedBIR;
        }

        public byte[] getActualBIR() {
            return actualBIRBinary;
        }
    }

    public static String getPlatformFromBala(String balaName, String packageName, String version) {
        return balaName.split(packageName + "-")[1].split("-" + version)[0];
    }

    /**
     * Contain compiled {@code BLangPackage} and Syntax tree.
     * This result is used to test sem-type relationships.
     *
     * @since 3.0.0
     */
    public static class PackageSyntaxTreePair {
        public final BLangPackage bLangPackage;
        public final SyntaxTree syntaxTree;

        public PackageSyntaxTreePair(BLangPackage bLangPackage, SyntaxTree syntaxTree) {
            this.bLangPackage = bLangPackage;
            this.syntaxTree = syntaxTree;
        }
    }
}
