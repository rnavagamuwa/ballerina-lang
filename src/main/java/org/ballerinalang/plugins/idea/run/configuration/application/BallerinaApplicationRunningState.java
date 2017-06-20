/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package org.ballerinalang.plugins.idea.run.configuration.application;

import com.intellij.execution.ExecutionException;
import com.intellij.execution.executors.DefaultDebugExecutor;
import com.intellij.execution.process.ProcessAdapter;
import com.intellij.execution.process.ProcessEvent;
import com.intellij.execution.process.ProcessHandler;
import com.intellij.execution.runners.ExecutionEnvironment;
import com.intellij.openapi.module.Module;
import org.ballerinalang.plugins.idea.run.configuration.BallerinaRunningState;
import org.ballerinalang.plugins.idea.run.configuration.RunConfigurationKind;
import org.ballerinalang.plugins.idea.util.BallerinaExecutor;
import org.ballerinalang.plugins.idea.util.BallerinaHistoryProcessListener;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

public class BallerinaApplicationRunningState extends BallerinaRunningState<BallerinaApplicationConfiguration> {

    private int myDebugPort = 5006;
    @Nullable
    private BallerinaHistoryProcessListener myHistoryProcessHandler;

    BallerinaApplicationRunningState(@NotNull ExecutionEnvironment env, @NotNull Module module,
                                     @NotNull BallerinaApplicationConfiguration configuration) {
        super(env, module, configuration);
    }

    @NotNull
    @Override
    protected ProcessHandler startProcess() throws ExecutionException {
        ProcessHandler processHandler = super.startProcess();
        processHandler.addProcessListener(new ProcessAdapter() {
            @Override
            public void startNotified(ProcessEvent event) {
                if (myHistoryProcessHandler != null) {
                    myHistoryProcessHandler.apply(processHandler);
                }
            }
        });
        return processHandler;
    }

    @Override
    protected BallerinaExecutor patchExecutor(@NotNull BallerinaExecutor executor) throws ExecutionException {
        RunConfigurationKind kind = getConfiguration().getRunKind();
        String parameters = myConfiguration.getPackage();
        if (parameters.isEmpty()) {
            parameters = myConfiguration.getFilePath();
        }
        BallerinaExecutor ballerinaExecutor = executor.withParameters("run").withParameters(kind.name().toLowerCase())
                .withParameterString(myConfiguration.getBallerinaToolParams()).withParameters(parameters);
        // If debugging mode is running, we need to add the debugging flag.
        if (isDebug()) {
            ballerinaExecutor.withParameters("--ballerina.debug", String.valueOf(myDebugPort));
        }
        return ballerinaExecutor;
    }

    public void setDebugPort(int debugPort) {
        myDebugPort = debugPort;
    }

    public void setHistoryProcessHandler(@Nullable BallerinaHistoryProcessListener historyProcessHandler) {
        myHistoryProcessHandler = historyProcessHandler;
    }

    /**
     * Indicates whether the debugging is invoked or not.
     *
     * @return {@code true} if debugging is running, {@code false} otherwise.
     */
    private boolean isDebug() {
        return DefaultDebugExecutor.EXECUTOR_ID.equals(getEnvironment().getExecutor().getId());
    }
}
