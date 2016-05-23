<%@ page import="org.wso2.carbon.event.execution.manager.stub.ExecutionManagerAdminServiceStub" %>
<%@ page import="org.wso2.carbon.event.execution.manager.ui.ExecutionManagerUIUtils" %>
<%@ page import="org.wso2.carbon.event.execution.manager.admin.dto.configuration.xsd.AttributeMappingDTO" %>
<%@ page import="org.wso2.carbon.event.execution.manager.admin.dto.configuration.xsd.StreamMappingDTO" %>
<%@ page import="org.apache.axis2.AxisFault" %>
<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
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
    try {
        String domainName = request.getParameter("domainName");
        String configuration = request.getParameter("configurationName");
        String streamMappingObjectArray = request.getParameter("streamMappingObjectArray");

        ExecutionManagerAdminServiceStub proxy = ExecutionManagerUIUtils.getExecutionManagerAdminService(config, session);
        //extract stream mapping strings from json string
        String[] valuesInQuotes = StringUtils.substringsBetween(streamMappingObjectArray, "[", "]");

        //extract each stream mapping string
        String[] streamMappingStrings = StringUtils.substringsBetween(valuesInQuotes[0], "{", "}");

        List<StreamMappingDTO> streamMappingDTOsList = new ArrayList<StreamMappingDTO>();
        List<AttributeMappingDTO> attributeMappingDTOsList = new ArrayList<AttributeMappingDTO>();

        //iterate each stream map and get stream map elements
        for (String streamMappingString : streamMappingStrings) {
            StreamMappingDTO streamMappingDTO = new StreamMappingDTO();

            String[] streamMapElements = streamMappingString.split(",");
            //iterate through each stream map element array
            for (int i = 0; i < streamMapElements.length; i++) {
                String[] keyValueArray = streamMapElements[i].split(":");
                if (i == 0) {
                    //extract toStream id
                    streamMappingDTO.setToStream(keyValueArray[1] + ":" + keyValueArray[2]);
                    System.out.println("stream: " + keyValueArray[1] + ":" + keyValueArray[2]);
                } else if (i == 1) {
                    //extract fromStream id
                    streamMappingDTO.setFromStream(keyValueArray[1] + ":" + keyValueArray[2]);
                    System.out.println("stream: " + keyValueArray[1] + ":" + keyValueArray[2]);
                } else {
                    //extract property mapping
                    if (!keyValueArray[1].equals("\"\"")) {
                        String[] properties = StringUtils.substringsBetween(keyValueArray[1], "\"", "\"")[0].split("\\$=");

                        if (properties != null) {
                            for (String property : properties) {
                                String[] propertyNameValueAndType = property.split("\\^=");
                                if (propertyNameValueAndType != null) {
                                    AttributeMappingDTO attributeMappingDTO = new AttributeMappingDTO();

                                    attributeMappingDTO.setFromAttribute(propertyNameValueAndType[0]);
                                    System.out.println("mappingAttribute: " + propertyNameValueAndType[0]);
                                    attributeMappingDTO.setToAttribute(propertyNameValueAndType[1]);
                                    System.out.println("mappedAttribute: " + propertyNameValueAndType[1]);
                                    attributeMappingDTO.setAttributeType(propertyNameValueAndType[2]);
                                    System.out.println("mappedAttributeType: " + propertyNameValueAndType[2]);

                                    //add attributeMappingDTO to attribute mapping dto array
                                    attributeMappingDTOsList.add(attributeMappingDTO);
                                }
                            }
                        }
                    }

                    if (i == 4) {
                        streamMappingDTO.setAttributeMappingDTOs(attributeMappingDTOsList.toArray());
                    }
                }
            }
            // add streamMappingDTO to streamMappingDTOs[]
            streamMappingDTOsList.add(streamMappingDTO);

            proxy.saveStreamMapping(streamMappingDTOsList.toArray(),configuration,domainName);
        }
    } catch (AxisFault e) {
        response.sendError(500);
    }
%>