/**
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
 *
 * Copyright (c) 2015 ForgeRock AS. All Rights Reserved
 *
 * The contents of this file are subject to the terms
 * of the Common Development and Distribution License
 * (the License). You may not use this file except in
 * compliance with the License.
 *
 * You can obtain a copy of the License at
 * http://forgerock.org/license/CDDLv1.0.html
 * See the License for the specific language governing
 * permission and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL
 * Header Notice in each file and include the License file
 * at http://forgerock.org/license/CDDLv1.0.html
 * If applicable, add the following below the CDDL Header,
 * with the fields enclosed by brackets [] replaced by
 * your own identifying information:
 * "Portions Copyrighted [year] [name of copyright owner]"
 *
 */

package org.forgerock.openidm.repo.opendj.embedded;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import org.restlet.data.ChallengeRequest;
import org.restlet.data.ChallengeResponse;
import org.restlet.data.ChallengeScheme;
import org.restlet.resource.ClientResource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Existing server configuration.
 */
public class ExistingServerConfig {
	
	final static Logger logger = LoggerFactory.getLogger(ExistingServerConfig.class);
	
    public static Map<String, String> getOpenDJSetupMap(String existingServerUrl, 
                                                        String username, 
                                                        String password) 
    throws StoreException {
        Map<String, String> remoteMap = new HashMap<String, String>();
        
        ChallengeResponse c2 = null;

        ClientResource r1 = new ClientResource(existingServerUrl + ReplicationResource.URI);
        r1.setChallengeResponse(ChallengeScheme.HTTP_DIGEST, username, password);
        ReplicationResource replicationResource = r1.wrap(ReplicationResource.class);
        ReplicationConfig remoteConfig = null;

        try {
            remoteConfig = replicationResource.getConfig();
        } catch (Exception ex) {
            logger.debug("DB_SET_UNAUTH " + existingServerUrl);
        }

        if (r1.getStatus().getCode() == 401) {
            ChallengeRequest c1 = null;

            for (ChallengeRequest challengeRequest : r1.getChallengeRequests()) {
                if (ChallengeScheme.HTTP_DIGEST.equals(challengeRequest.getScheme())) {
                    c1 = challengeRequest;
                    break;
                }
            }

            c2 = new ChallengeResponse(c1, r1.getResponse(),
                                                        username,
                                                        password.toCharArray());
            logger.debug("DB_SET_AUTH_OK");
        } else {
            logger.debug("DB_SET_AUTH_NREQ");
        }

        r1.setChallengeResponse(c2);

        try {
            remoteConfig = replicationResource.getConfig();
        } catch (Exception ex) {
            System.err.println(ex.getMessage());
        }
        
        remoteMap.put(Constants.OPENDJ_ADMIN_PORT, remoteConfig.getAdminPort());
        remoteMap.put(Constants.OPENDJ_DS_MGR_DN, remoteConfig.getDsMgrDN());
        remoteMap.put(Constants.OPENDJ_DS_MGR_PASSWD, remoteConfig.getDsMgrPasswd());
        remoteMap.put(Constants.EXISTING_SERVER_URL, remoteConfig.getExistingServerUrl());
        remoteMap.put(Constants.HOST_URL, remoteConfig.getHostUrl());
        remoteMap.put(Constants.OPENDJ_JMX_PORT, remoteConfig.getJmxPort());
        remoteMap.put(Constants.OPENDJ_LDAP_PORT, remoteConfig.getLdapPort());
        remoteMap.put(Constants.OPENDJ_ROOT, remoteConfig.getOdjRoot());
        remoteMap.put(Constants.OPENDJ_REPL_PORT, remoteConfig.getReplPort());
        remoteMap.put(Constants.OPENDJ_SUFFIX, remoteConfig.getSessionDBSuffix());
        remoteMap.put(Constants.HOST_FQDN, getHostnameFromUrl(remoteConfig.getHostUrl()));
        
        return remoteMap;
    }
    
    private static String getHostnameFromUrl(String hostUrl) 
    throws StoreException {
        URL hostname = null;
        
        try {
            hostname = new URL(hostUrl);
        } catch (MalformedURLException mre) {
            logger.debug("DB_MAL_URL " + hostUrl);
            throw new StoreException("DB_MAL_URL " + hostUrl, mre);
        }
        
        return hostname.getHost();
    }
}