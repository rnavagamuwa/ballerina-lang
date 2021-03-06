// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/auth;
import ballerina/crypto;
import ballerina/log;
import ballerina/system;

/////////////////////////////
/// HTTP Listener Endpoint ///
/////////////////////////////
# This is used for creating HTTP server endpoints. An HTTP server endpoint is capable of responding to
# remote callers. The `Listener` is responsible for initializing the endpoint using the provided configurations.
public type Listener object {

    *AbstractListener;

    private int port = 0;
    private ServiceEndpointConfiguration config = {};
    private string instanceId;

    public function __start() returns error? {
        return self.start();
    }

    public function __stop() returns error? {
        return self.stop();
    }

    public function __attach(service s, map<any> annotationData) returns error? {
        return self.register(s, annotationData);
    }

    public function __init(int port, ServiceEndpointConfiguration? config = ()) {
        self.instanceId = system:uuid();
        self.config = config ?: {};
        self.port = port;
        self.init(self.config);
    }

    # Gets invoked during module initialization to initialize the endpoint.
    #
    # + c - Configurations for HTTP service endpoints
    public function init(ServiceEndpointConfiguration c);

    public extern function initEndpoint() returns error?;

    # Gets invoked when attaching a service to the endpoint.
    #
    # + s - The service that needs to be attached
    # + return - An `error` if there is any error occured during the service attachment process or else nil
    extern function register(service s, map<any> annotationData) returns error?;

    # Starts the registered service.
    extern function start();

    # Stops the registered service.
    extern function stop();
};

public function Listener.init(ServiceEndpointConfiguration c) {
    self.config = c;
    var authProviders = self.config.authProviders;
    if (authProviders is AuthProvider[]) {
        var providers = authProviders;
        if (providers.length() > 0) {
            var secureSocket = self.config.secureSocket;
            if (secureSocket is ServiceSecureSocket) {
                addAuthFiltersForSecureListener(self.config, self.instanceId);
            } else {
                error err = error("Secure sockets have not been cofigured in order to enable auth providers.");
                panic err;
            }
        }
    }
    var err = self.initEndpoint();
    if (err is error) {
        panic err;
    }
}

# Presents a read-only view of the remote address.
#
# + host - The remote host name/IP
# + port - The remote port
public type Remote record {
    string host = "";
    int port = 0;
    !...;
};

# Presents a read-only view of the local address.
#
# + host - The local host name/IP
# + port - The local port
public type Local record {
    string host = "";
    int port = 0;
    !...;
};

# Configures limits for requests. If these limits are violated, the request is rejected.
#
# + maxUriLength - Maximum allowed length for a URI. Exceeding this limit will result in a
#                  `414 - URI Too Long` response.
# + maxHeaderSize - Maximum allowed size for headers. Exceeding this limit will result in a
#                   `413 - Payload Too Large` response.
# + maxEntityBodySize - Maximum allowed size for the entity body. Exceeding this limit will result in a
#                       `413 - Payload Too Large` response.
public type RequestLimits record {
    int maxUriLength = -1;
    int maxHeaderSize = -1;
    int maxEntityBodySize = -1;
    !...;
};

# Provides a set of configurations for HTTP service endpoints.
#
# + host - The host name/IP of the endpoint
# + keepAlive - Can be set to either `KEEPALIVE_AUTO`, which respects the `connection` header, or `KEEPALIVE_ALWAYS`,
#               which always keeps the connection alive, or `KEEPALIVE_NEVER`, which always closes the connection
# + secureSocket - The SSL configurations for the service endpoint. This needs to be configured in order to
#                  communicate through HTTPS.
# + httpVersion - Highest HTTP version supported by the endpoint
# + requestLimits - Configures the parameters for request validation
# + filters - If any pre-processing needs to be done to the request before dispatching the request to the
#             resource, filters can applied
# + timeoutMillis - Period of time in milliseconds that a connection waits for a read/write operation. Use value 0 to
#                   disable timeout
# + maxPipelinedRequests - Defines the maximum number of requests that can be processed at a given time on a single
#                          connection. By default 10 requests can be pipelined on a single cinnection and user can
#                          change this limit appropriately. This will be applicable only for HTTP 1.1
# + authProviders - The array of authentication providers which are used to authenticate the users
# + positiveAuthzCache - Caching configurations for positive authorizations
# + negativeAuthzCache - Caching configurations for negative authorizations
public type ServiceEndpointConfiguration record {
    string host = "0.0.0.0";
    KeepAlive keepAlive = KEEPALIVE_AUTO;
    ServiceSecureSocket? secureSocket = ();
    string httpVersion = "1.1";
    RequestLimits? requestLimits = ();
    Filter[] filters = [];
    int timeoutMillis = DEFAULT_LISTENER_TIMEOUT;
    int maxPipelinedRequests = MAX_PIPELINED_REQUESTS;
    AuthProvider[]? authProviders = ();
    AuthCacheConfig positiveAuthzCache = {};
    AuthCacheConfig negativeAuthzCache = {};
    !...;
};

# Configures the SSL/TLS options to be used for HTTP service.
#
# + trustStore - Configures the trust store to be used
# + keyStore - Configures the key store to be used
# + certFile - A file containing the certificate of the server
# + keyFile - A file containing the private key of the server
# + keyPassword - Password of the private key if it is encrypted
# + trustedCertFile - A file containing a list of certificates or a single certificate that the server trusts
# + protocol - SSL/TLS protocol related options
# + certValidation - Certificate validation against CRL or OCSP related options
# + ciphers - List of ciphers to be used (e.g.: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
#             TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA)
# + sslVerifyClient - The type of client certificate verification
# + shareSession - Enable/disable new SSL session creation
# + handshakeTimeout - SSL handshake time out
# + sessionTimeout - SSL session time out
# + ocspStapling - Enable/disable OCSP stapling
public type ServiceSecureSocket record {
    TrustStore? trustStore = ();
    KeyStore? keyStore = ();
    string certFile = "";
    string keyFile = "";
    string keyPassword = "";
    string trustedCertFile = "";
    Protocols? protocol = ();
    ValidateCert? certValidation = ();
    string[] ciphers = ["TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256",
                        "TLS_DHE_RSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA",
                        "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA", "TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
                        "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
                        "TLS_DHE_RSA_WITH_AES_128_GCM_SHA256"];
    string sslVerifyClient = "";
    boolean shareSession = true;
    int? handshakeTimeout = ();
    int? sessionTimeout = ();
    ServiceOcspStapling? ocspStapling = ();
    !...;
};

# Provides a set of configurations for controlling the authorization caching behaviour of the endpoint.
#
# + enabled - Specifies whether authorization caching is enabled. Caching is enabled by default.
# + capacity - The capacity of the cache
# + expiryTimeMillis - The number of milliseconds to keep an entry in the cache
# + evictionFactor - The fraction of entries to be removed when the cache is full. The value should be
#                    between 0 (exclusive) and 1 (inclusive).
public type AuthCacheConfig record {
    boolean enabled = true;
    int capacity = 100;
    int expiryTimeMillis = 5 * 1000; // 5 seconds;
    float evictionFactor = 1;
    !...;
};

# Configuration for authentication providers.
#
# + id - Authentication provider instance id
# + scheme - Authentication scheme
# + authStoreProvider - Authentication store provider (Config, LDAP, etc.) implementation
# + config - Configuration related to the selected authentication provider.
public type AuthProvider record {
    string id = "";
    InboundAuthScheme? scheme = ();
    AuthStoreProvider? authStoreProvider = ();
    auth:LdapAuthProviderConfig|auth:ConfigAuthProviderConfig|auth:JWTAuthProviderConfig? config = ();
    !...;
};

# Defines the possible values for the keep-alive configuration in service and client endpoints.
public type KeepAlive KEEPALIVE_AUTO|KEEPALIVE_ALWAYS|KEEPALIVE_NEVER;

# Decides to keep the connection alive or not based on the `connection` header of the client request }
public const KEEPALIVE_AUTO = "AUTO";
# Keeps the connection alive irrespective of the `connection` header value }
public const KEEPALIVE_ALWAYS = "ALWAYS";
# Closes the connection irrespective of the `connection` header value }
public const KEEPALIVE_NEVER = "NEVER";

# Add authn and authz filters
#
# + config - `ServiceEndpointConfiguration` instance
# + instanceId - Endpoint instance id
function addAuthFiltersForSecureListener(ServiceEndpointConfiguration config, string instanceId) {
    // add authentication and authorization filters as the first two filters.
    // if there are any other filters specified, those should be added after the authn and authz filters.
    if (config.filters.length() == 0) {
        // can add authn and authz filters directly
        config.filters = createAuthFiltersForSecureListener(config, instanceId);
    } else {
        Filter[] newFilters = createAuthFiltersForSecureListener(config, instanceId);
        // add existing filters next
        int i = 0;
        while (i < config.filters.length()) {
        newFilters[i + (newFilters.length())] = config.filters[i];
        i = i + 1;
        }
        config.filters = newFilters;
    }
}

# Create an array of auth and authz filters.
#
# + config - `ServiceEndpointConfiguration` instance
# + instanceId - Endpoint instance id
# + return - Array of Filters comprising of authn and authz Filters
function createAuthFiltersForSecureListener(ServiceEndpointConfiguration config, string instanceId) returns (Filter[]) {
    // parse and create authentication handlers
    AuthHandlerRegistry registry = new;
    Filter[] authFilters = [];
    var authProviderList = config.authProviders;
    if (authProviderList is AuthProvider[]) {
        if (authProviderList.length() > 0) {
            foreach var provider in authProviderList {
                if (provider.id.length() > 0) {
                    registry.add(provider.id, createAuthHandler(provider, instanceId));
                } else {
                    string providerId = system:uuid();
                    registry.add(providerId, createAuthHandler(provider, instanceId));
                }
            }

            AuthnHandlerChain authnHandlerChain = new(registry);
            AuthnFilter authnFilter = new(authnHandlerChain);
            cache:Cache positiveAuthzCache = new(expiryTimeMillis = config.positiveAuthzCache.expiryTimeMillis,
            capacity = config.positiveAuthzCache.capacity,
            evictionFactor = config.positiveAuthzCache.evictionFactor);
            cache:Cache negativeAuthzCache = new(expiryTimeMillis = config.negativeAuthzCache.expiryTimeMillis,
            capacity = config.negativeAuthzCache.capacity,
            evictionFactor = config.negativeAuthzCache.evictionFactor);
            auth:AuthStoreProvider authStoreProvider = new;

            foreach var provider in authProviderList {
                var authProviderConfig = provider.config;
                if (provider.scheme == BASIC_AUTH) {
                    if (provider.authStoreProvider == LDAP_AUTH_STORE) {
                        if (authProviderConfig is auth:LdapAuthProviderConfig) {
                            auth:LdapAuthStoreProvider ldapAuthStoreProvider = new(authProviderConfig, instanceId);
                            authStoreProvider = ldapAuthStoreProvider;
                        } else {
                            error e = error("LDAP auth provider config not provided");
                            panic e;
                        }
                    } else if (provider.authStoreProvider == CONFIG_AUTH_STORE) {
                        auth:ConfigAuthStoreProvider configAuthStoreProvider;
                        if (authProviderConfig is auth:ConfigAuthProviderConfig) {
                            configAuthStoreProvider = new(authProviderConfig);
                        } else {
                            configAuthStoreProvider = new({});
                        }
                        authStoreProvider = configAuthStoreProvider;
                    } else {
                        error configError = error("Unsupported auth store provider");
                        panic configError;
                    }
                }
            }

            HttpAuthzHandler authzHandler = new(authStoreProvider, positiveAuthzCache, negativeAuthzCache);
            AuthzFilter authzFilter = new(authzHandler);
            authFilters[0] = authnFilter;
            authFilters[1] = authzFilter;
        }
    }
    return authFilters;
}

function createAuthHandler(AuthProvider authProvider, string instanceId) returns HttpAuthnHandler {
    var authProviderConfig = authProvider.config;
    if (authProvider.scheme == BASIC_AUTH) {
        auth:AuthStoreProvider authStoreProvider = new;
        if (authProvider.authStoreProvider == CONFIG_AUTH_STORE) {
            auth:ConfigAuthStoreProvider configAuthStoreProvider;
            if (authProviderConfig is auth:ConfigAuthProviderConfig) {
                configAuthStoreProvider = new(authProviderConfig);
            } else {
                configAuthStoreProvider = new({});
            }
            authStoreProvider = configAuthStoreProvider;
        } else if (authProvider.authStoreProvider == LDAP_AUTH_STORE) {
            if (authProviderConfig is auth:LdapAuthProviderConfig) {
                auth:LdapAuthStoreProvider ldapAuthStoreProvider = new(authProviderConfig, instanceId);
                authStoreProvider = ldapAuthStoreProvider;
            } else {
                error e = error("LDAP auth provider config not provided");
                panic e;
            }
        } else {
            error e = error("Unsupported auth store provider");
            panic e;
        }
        HttpBasicAuthnHandler basicAuthHandler = new(authStoreProvider);
        return basicAuthHandler;
    } else if (authProvider.scheme == JWT_AUTH){
        if (authProviderConfig is auth:JWTAuthProviderConfig) {
            auth:JWTAuthProvider jwtAuthProvider = new(authProviderConfig);
            HttpJwtAuthnHandler jwtAuthnHandler = new(jwtAuthProvider);
            return jwtAuthnHandler;
        } else {
            error e = error("JWT auth provider config not provided");
            panic e;
        }
    } else {
        error e = error("Unsupported auth scheme");
        panic e;
    }
}

//////////////////////////////////
/// WebSocket Service Endpoint ///
//////////////////////////////////
# Represents a WebSocket service endpoint.
// public type WebSocketListener Listener;
public type WebSocketListener object {

    *AbstractListener;

    private Listener httpEndpoint;

    public function __start() returns error? {
        return self.httpEndpoint.start();
    }

    public function __stop() returns error? {
        return self.httpEndpoint.stop();
    }

    public function __attach(service s, map<any> annotationData) returns error? {
        return self.httpEndpoint.register(s, annotationData);
    }


    # Gets invoked during module initialization to initialize the endpoint.
    #
    # + port - The port of the endpoint
    # + config - The `ServiceEndpointConfiguration` of the endpoint
    public function __init(int port, ServiceEndpointConfiguration? config = ()) {
        self.httpEndpoint = new(port, config = config);
    }

};
