<%@ taglib prefix="fmt" uri="http://java.sun.com/jstl/fmt" %>
<%@ page import="org.wso2.carbon.event.execution.manager.stub.ExecutionManagerAdminServiceStub" %>
<%@ page import="org.wso2.carbon.event.execution.manager.ui.ExecutionManagerUIUtils" %>
<%@ page import="org.wso2.carbon.event.execution.manager.admin.dto.configuration.xsd.TemplateConfigurationDTO" %>
<%@ page import="org.wso2.carbon.event.execution.manager.admin.dto.configuration.xsd.ParameterDTOE" %>
<%@ page import="org.apache.axis2.AxisFault" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="org.wso2.carbon.event.stream.stub.EventStreamAdminServiceStub" %>
<%--
  ~ Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  --%>

<%
    //todo: rename to ScenarioConfigurationDTO,remove cron expression

    String domainName = request.getParameter("domainName");
    String configuration = request.getParameter("configurationName");
    String saveType = request.getParameter("saveType");
    String description = request.getParameter("description");
    String parametersJson = request.getParameter("parameters");
    String templateType = request.getParameter("templateType");
    String cronExpression = request.getParameter("executionParameters");
    String valueSeparator = "::";

    ParameterDTOE[] parameters;

    ExecutionManagerAdminServiceStub proxy = ExecutionManagerUIUtils.getExecutionManagerAdminService(config, session);
    try {
        if (saveType.equals("delete")) {
            proxy.deleteConfiguration(domainName, configuration);
        } else {

            TemplateConfigurationDTO templateConfigurationDTO = new TemplateConfigurationDTO();

            templateConfigurationDTO.setName(configuration);
            templateConfigurationDTO.setFrom(domainName);
            templateConfigurationDTO.setDescription(description);
            templateConfigurationDTO.setType(templateType);

            if (parametersJson.length() < 1) {
               parameters = new ParameterDTOE[0];

            } else {
                String[] parameterStrings = parametersJson.split(",");
                parameters = new ParameterDTOE[parameterStrings.length];
                int index = 0;

                for (String parameterString : parameterStrings) {
                    ParameterDTOE parameterDTO = new ParameterDTOE();
                    parameterDTO.setName(parameterString.split(valueSeparator)[0]);
                    parameterDTO.setValue(parameterString.split(valueSeparator)[1]);
                    parameters[index] = parameterDTO;
                    index++;
                }
            }

            templateConfigurationDTO.setParameterDTOs(parameters);

            if (cronExpression != null && cronExpression.length() > 0) {
                        templateConfigurationDTO.setExecutionParameters(cronExpression);
            }

            //checks the "proxy.saveConfiguration(templateConfigurationDTO)" return value for not null and build stream mapping div
            if (proxy.saveConfiguration(templateConfigurationDTO) != null) {
                String toStreamIDArray[] = proxy.saveConfiguration(templateConfigurationDTO);
                String toStreamNameID = "";
                EventStreamAdminServiceStub eventStreamAdminServiceStub = ExecutionManagerUIUtils.getEventStreamAdminService(config,
                        session, request);
                String[] streamIds = eventStreamAdminServiceStub.getStreamNames();
%>
<div class="container col-md-12 marg-top-20" id="streamMappingInnerDivID">
    <%
        for (int i = 0; i < toStreamIDArray.length; i++) {
            toStreamNameID = toStreamIDArray[i];
    %>
    <div class="container col-md-12 marg-top-20" id="streamMappingConfigurationID_<%=i%>">

        <h4><fmt:message key='template.stream.header.text'/></h4>

        <label class="input-label col-md-5"><fmt:message key='template.label.to.stream.name'/></label>

        <div class="input-control input-full-width col-md-7 text">
            <input type="text" id="toStreamID_<%=i%>"
                   value="<%=toStreamNameID%>" readonly="true"/>
        </div>

        <label class="input-label col-md-5"><fmt:message key='template.label.from.stream.name'/></label>

        <%--todo: add new js function to load mapping table for updated values--%>
        <div class="input-control input-full-width col-md-7 text">
            <select id="fromStreamID_<%=i%>" onchange="loadMappingFromStreamAttributes(<%=i%>)">
                <option selected disabled>Choose from here</option>
                <%
                    if (streamIds != null) {
                        Arrays.sort(streamIds);
                        for (String aStreamId : streamIds) {
                %>
                <option id="fromStreamOptionID"><%=aStreamId%>
                </option>
                <%
                        }
                    }
                %>
            </select>
        </div>

        <div id="outerDiv_<%=i%>" class="input-label col-md-5">
        </div>

    </div>
    <%
        }
    %>
    <div class="action-container">
        <button type="button"
                class="btn btn-default btn-add col-md-2 col-xs-12 pull-right marg-right-15"
                onclick="saveStreamConfiguration(<%=toStreamIDArray.length%>,'domain_configurations_ajaxprocessor.jsp?domainName=<%=domainName%>',<%=domainName%>,<%=configuration%>)">
            <fmt:message key='template.add.stream.button.text'/>
        </button>
    </div>
</div>
<%
            } else {
                proxy.saveConfiguration(templateConfigurationDTO);
            }
        }
    } catch (AxisFault e) {
        response.sendError(500);
    }


%>