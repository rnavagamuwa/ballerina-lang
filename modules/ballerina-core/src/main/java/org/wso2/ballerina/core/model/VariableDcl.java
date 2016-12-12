/*
 * Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.wso2.ballerina.core.model;

import org.wso2.ballerina.core.model.types.Type;

/**
 * {@code Variable} represent a Variable declaration
 *
 * <p>
 * Ballerina has variables of various types. The type system includes built-in primitives,
 * a collection of built-in structured types and array and record type constructors.
 *
 * @since 1.0.0
 */
@SuppressWarnings("unused")
public class VariableDcl {

    private Type type;
    private Identifier identifier;
    private String value;

    /**
     * @param type       Type of the variable
     * @param identifier Identifier of the variable
     * @param value      bValueRef of the variable
     */
    public VariableDcl(Type type, Identifier identifier, String value) {
        this.type = type;
        this.identifier = identifier;
        this.value = value;
    }

    public VariableDcl(Type type, Identifier identifier) {
        this.type = type;
        this.identifier = identifier;
    }

    /**
     * Get the type of the variable
     *
     * @return type of the variable
     */
    public Type getType() {
        return type;
    }

    /**
     * Get the identifier of the variable declaration
     *
     * @return identifier of the variable declaration
     */
    public Identifier getIdentifier() {
        return identifier;
    }

    /**
     * Get the bValueRef of the variable
     *
     * @return bValueRef of the variable
     */
    public String getValue() {
        return value;
    }
}
