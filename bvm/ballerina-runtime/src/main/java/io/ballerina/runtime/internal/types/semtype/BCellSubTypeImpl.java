/*
 *  Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.runtime.internal.types.semtype;

import io.ballerina.runtime.api.types.semtype.Bdd;
import io.ballerina.runtime.api.types.semtype.Builder;
import io.ballerina.runtime.api.types.semtype.Conjunction;
import io.ballerina.runtime.api.types.semtype.Context;
import io.ballerina.runtime.api.types.semtype.Core;
import io.ballerina.runtime.api.types.semtype.SemType;
import io.ballerina.runtime.api.types.semtype.SubType;

import java.util.Objects;
import java.util.function.Predicate;

/**
 * Runtime representation of CellSubType.
 *
 * @since 2201.12.0
 */
final class BCellSubTypeImpl extends BCellSubType implements DelegatedSubType {

    private final Bdd inner;

    BCellSubTypeImpl(Bdd inner) {
        super(inner.isAll(), inner.isNothing());
        this.inner = inner;
    }

    @Override
    public SubType union(SubType other) {
        if (other instanceof BCellSubType otherCell) {
            return createDelegate(inner.union(otherCell.inner()));
        }
        throw new IllegalArgumentException("union of different subtypes");
    }

    @Override
    public SubType intersect(SubType other) {
        if (other instanceof BCellSubType otherCell) {
            return createDelegate(inner.intersect(otherCell.inner()));
        }
        throw new IllegalArgumentException("intersect of different subtypes");
    }

    @Override
    public SubType complement() {
        return createDelegate(inner.complement());
    }

    @Override
    public boolean isEmpty(Context cx) {
        return Bdd.bddEvery(cx, inner, BCellSubTypeImpl::cellFormulaIsEmpty);
    }

    @Override
    public SubType diff(SubType other) {
        if (other instanceof BCellSubType otherCell) {
            return createDelegate(inner.diff(otherCell.inner()));
        }
        throw new IllegalArgumentException("diff of different subtypes");

    }

    @Override
    public SubTypeData data() {
        throw new IllegalStateException("unimplemented");
    }

    private static boolean cellFormulaIsEmpty(Context cx, Conjunction posList, Conjunction negList) {
        CellAtomicType combined;
        if (posList == null) {
            combined = CellAtomicType.from(Builder.getValType(), CellAtomicType.CellMutability.CELL_MUT_UNLIMITED);
        } else {
            combined = CellAtomicType.cellAtomType(posList.atom());
            Conjunction p = posList.next();
            while (p != null) {
                combined = CellAtomicType.intersectCellAtomicType(combined, CellAtomicType.cellAtomType(p.atom()));
                p = p.next();
            }
        }
        return !cellInhabited(cx, combined, negList);
    }

    private static boolean cellInhabited(Context cx, CellAtomicType posCell, Conjunction negList) {
        SemType pos = posCell.ty();
        if (Core.isEmpty(cx, pos)) {
            return false;
        }
        return switch (posCell.mut()) {
            case CELL_MUT_NONE -> cellMutNoneInhabited(cx, pos, negList);
            case CELL_MUT_LIMITED -> cellMutLimitedInhabited(cx, pos, negList);
            default -> cellMutUnlimitedInhabited(cx, pos, negList);
        };
    }

    private static boolean cellMutUnlimitedInhabited(Context cx, SemType pos, Conjunction negList) {
        Conjunction neg = negList;
        while (neg != null) {
            if (CellAtomicType.cellAtomType(neg.atom()).mut() == CellAtomicType.CellMutability.CELL_MUT_LIMITED &&
                    Core.isSameType(cx, Builder.getValType(), CellAtomicType.cellAtomType(neg.atom()).ty())) {
                return false;
            }
            neg = neg.next();
        }
        SemType negListUnionResult = filteredCellListUnion(negList,
                conjunction -> CellAtomicType.cellAtomType(conjunction.atom()).mut() ==
                        CellAtomicType.CellMutability.CELL_MUT_UNLIMITED);
        // We expect `isNever` condition to be `true` when there are no negative atoms with unlimited mutability.
        // Otherwise, we do `isEmpty` to conclude on the inhabitance.
        return Core.isNever(negListUnionResult) || !Core.isEmpty(cx, Core.diff(pos, negListUnionResult));
    }

    private static boolean cellMutLimitedInhabited(Context cx, SemType pos, Conjunction negList) {
        if (negList == null) {
            return true;
        }
        CellAtomicType negAtomicCell = CellAtomicType.cellAtomType(negList.atom());
        if ((negAtomicCell.mut().compareTo(CellAtomicType.CellMutability.CELL_MUT_LIMITED) >= 0) &&
                Core.isEmpty(cx, Core.diff(pos, negAtomicCell.ty()))) {
            return false;
        }
        return cellMutLimitedInhabited(cx, pos, negList.next());
    }

    private static boolean cellMutNoneInhabited(Context cx, SemType pos, Conjunction negList) {
        SemType negListUnionResult = cellListUnion(negList);
        // We expect `isNever` condition to be `true` when there are no negative atoms.
        // Otherwise, we do `isEmpty` to conclude on the inhabitance.
        return Core.isNever(negListUnionResult) || !Core.isEmpty(cx, Core.diff(pos, negListUnionResult));
    }

    private static SemType cellListUnion(Conjunction negList) {
        return filteredCellListUnion(negList, neg -> true);
    }

    private static SemType filteredCellListUnion(Conjunction negList, Predicate<Conjunction> predicate) {
        SemType negUnion = Builder.getNeverType();
        Conjunction neg = negList;
        while (neg != null) {
            if (predicate.test(neg)) {
                negUnion = Core.union(negUnion, CellAtomicType.cellAtomType(neg.atom()).ty());
            }
            neg = neg.next();
        }
        return negUnion;
    }

    @Override
    public Bdd inner() {
        return inner;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof BCellSubTypeImpl other)) {
            return false;
        }
        return Objects.equals(inner, other.inner);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(inner);
    }
}
