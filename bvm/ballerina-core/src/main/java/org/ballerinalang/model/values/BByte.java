/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package org.ballerinalang.model.values;

import org.ballerinalang.model.types.BType;
import org.ballerinalang.model.types.BTypes;

import java.math.BigDecimal;
import java.math.MathContext;
import java.util.Map;

/**
 * The {@code BByte} represents a byte value in Ballerina.
 *
 * @since 0.980
 */
public final class BByte extends BValueType implements BRefType<Byte> {

    private byte value;

    public BByte(byte value) {
        this.value = value;
    }

    private BType type = BTypes.typeByte;

    @Override
    public byte byteValue() {
        return this.value;
    }

    @Override
    public long intValue() {
        return Byte.toUnsignedInt(value);
    }

    @Override
    public double floatValue() {
        return Byte.toUnsignedInt(value);
    }

    @Override
    public BigDecimal decimalValue() {
        return (new BigDecimal(Byte.toUnsignedInt(value), MathContext.DECIMAL128))
                .setScale(1, BigDecimal.ROUND_HALF_EVEN);
    }

    @Override
    public boolean booleanValue() {
        return false;
    }

    @Override
    public String stringValue() {
        return String.valueOf(Byte.toUnsignedInt(value));
    }

    @Override
    public BType getType() {
        return type;
    }

    @Override
    public void setType(BType type) {
        this.type = type;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }

        if (obj == null || getClass() != obj.getClass()) {
            return false;
        }

        BByte that = (BByte) obj;
        return value == that.value;
    }

    @Override
    public Byte value() {
        return this.value;
    }

    @Override
    public BValue copy(Map<BValue, BValue> refs) {
        return this;
    }

    @Override
    public int hashCode() {
        return Byte.hashCode(value);
    }
}
