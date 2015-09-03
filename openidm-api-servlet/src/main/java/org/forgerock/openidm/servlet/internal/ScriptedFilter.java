/*
 * The contents of this file are subject to the terms of the Common Development and
 * Distribution License (the License). You may not use this file except in compliance with the
 * License.
 *
 * You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
 * specific language governing permission and limitations under the License.
 *
 * When distributing Covered Software, include this CDDL Header Notice in each file and include
 * the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
 * Header, with the fields enclosed by brackets [] replaced by your own identifying
 * information: "Portions copyright [year] [name of copyright owner]".
 *
 * Copyright 2013-2015 ForgeRock AS.
 */

package org.forgerock.openidm.servlet.internal;

import static org.forgerock.util.promise.Promises.newResultPromise;

import org.apache.commons.lang3.tuple.Pair;
import org.forgerock.http.Context;
import org.forgerock.json.JsonPointer;
import org.forgerock.json.resource.ActionRequest;
import org.forgerock.json.resource.ActionResponse;
import org.forgerock.json.resource.CreateRequest;
import org.forgerock.json.resource.DeleteRequest;
import org.forgerock.json.resource.Filter;
import org.forgerock.json.resource.PatchRequest;
import org.forgerock.json.resource.QueryRequest;
import org.forgerock.json.resource.QueryResourceHandler;
import org.forgerock.json.resource.QueryResponse;
import org.forgerock.json.resource.ReadRequest;
import org.forgerock.json.resource.Request;
import org.forgerock.json.resource.RequestHandler;
import org.forgerock.json.resource.ResourceException;
import org.forgerock.json.resource.ResourceResponse;
import org.forgerock.json.resource.Response;
import org.forgerock.json.resource.ServiceUnavailableException;
import org.forgerock.json.resource.UpdateRequest;
import org.forgerock.script.Script;
import org.forgerock.script.ScriptEntry;
import org.forgerock.script.engine.Utils;
import org.forgerock.util.AsyncFunction;
import org.forgerock.util.promise.Promise;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A router filter that allows hook on each CRUDPAQ operation at the following invocation points:
 * <ul>
 *     <li><code>onRequest</code> - before the request has been handled</li>
 *     <li><code>onResponse</code> - after the request invocation has completed successfully  and a response is available</li>
 *     <li><code>onFailure</code> - after the request invocation has completed with an exception</li>
 * </ul>
 */
public class ScriptedFilter implements Filter {

    private static final Logger logger = LoggerFactory.getLogger(ScriptedFilter.class);

    /** the onRequest script and the config path at which it is defined */
    private final Pair<JsonPointer, ScriptEntry> onRequest;
    /** the onResponse script and the config path at which it is defined */
    private final Pair<JsonPointer, ScriptEntry> onResponse;
    /** the onFailure script and the config path at which it is defined */
    private final Pair<JsonPointer, ScriptEntry> onFailure;

    public ScriptedFilter(
            Pair<JsonPointer, ScriptEntry> onRequest,
            Pair<JsonPointer, ScriptEntry> onResponse,
            Pair<JsonPointer, ScriptEntry> onFailure) {
        this.onRequest = onRequest;
        this.onResponse = onResponse;
        this.onFailure = onFailure;
    }

    @Override
    public Promise<ActionResponse, ResourceException> filterAction(
            final Context context, final ActionRequest request, final RequestHandler next) {
        return filterResourceResponseRequest(context, request,
                new AsyncFunction<Request, ActionResponse, ResourceException>() {
                    @Override
                    public Promise<ActionResponse, ResourceException> apply(Request value) {
                        return next.handleAction(context, request);
                    }
                });
    }

    @Override
    public Promise<ResourceResponse, ResourceException> filterCreate(
            final Context context, final CreateRequest request, final RequestHandler next) {
        return filterResourceResponseRequest(context, request,
                new AsyncFunction<Request, ResourceResponse, ResourceException>() {
                    @Override
                    public Promise<ResourceResponse, ResourceException> apply(Request value) {
                        return next.handleCreate(context, request);
                    }
                });
    }

    @Override
    public Promise<ResourceResponse, ResourceException> filterDelete(
            final Context context, final DeleteRequest request, final RequestHandler next) {
        return filterResourceResponseRequest(context, request,
                new AsyncFunction<Request, ResourceResponse, ResourceException>() {
                    @Override
                    public Promise<ResourceResponse, ResourceException> apply(Request value) {
                        return next.handleDelete(context, request);
                    }
                });
    }

    @Override
    public Promise<ResourceResponse, ResourceException> filterPatch(
            final Context context, final PatchRequest request, final RequestHandler next) {
        return filterResourceResponseRequest(context, request,
                new AsyncFunction<Request, ResourceResponse, ResourceException>() {
                    @Override
                    public Promise<ResourceResponse, ResourceException> apply(Request value) {
                        return next.handlePatch(context, request);
                    }
                });
    }

    @Override
    public Promise<ResourceResponse, ResourceException> filterRead(
            final Context context, final ReadRequest request, final RequestHandler next) {
        return filterResourceResponseRequest(context, request,
                new AsyncFunction<Request, ResourceResponse, ResourceException>() {
                    @Override
                    public Promise<ResourceResponse, ResourceException> apply(Request value) {
                        return next.handleRead(context, request);
                    }
                });
    }

    @Override
    public Promise<ResourceResponse, ResourceException> filterUpdate(
            final Context context, final UpdateRequest request, final RequestHandler next) {
        return filterResourceResponseRequest(context, request,
                new AsyncFunction<Request, ResourceResponse, ResourceException>() {
                    @Override
                    public Promise<ResourceResponse, ResourceException> apply(Request value) {
                        return next.handleUpdate(context, request);
                    }
                });
    }

    @Override
    public Promise<QueryResponse, ResourceException> filterQuery(
            final Context context, final QueryRequest request, final QueryResourceHandler handler,
            final RequestHandler next) {
        return filterResourceResponseRequest(context, request,
                new AsyncFunction<Request, QueryResponse, ResourceException>() {
                    @Override
                    public Promise<QueryResponse, ResourceException> apply(Request value) throws ResourceException {
                        return next.handleQuery(context, request, handler);
                    }
                });
    }

    public <R extends Response> Promise<R, ResourceException> filterResourceResponseRequest(
            final Context context,
            final Request request,
            final AsyncFunction<Request, R, ResourceException> handleRequest) {
        // evaluate the onRequest script
        return evaluateOnRequest(context, request)
                // then (if no error), handle the request
                .thenAsync(handleRequest)
                // then either
                .thenAsync(
                        // evaluate the onResponse script for a successful response
                        new AsyncFunction<R, R, ResourceException>() {
                            @Override
                            public Promise<R, ResourceException> apply(R response) throws ResourceException {
                                return evaluateOnResponse(context, request, response);
                            }
                        },
                        // evaluate the onFailure script with the error
                        new AsyncFunction<ResourceException, R, ResourceException>() {
                            @Override
                            public Promise<R, ResourceException> apply(ResourceException error) throws ResourceException {
                                return evaluateOnFailure(context, request, error);
                            }
                        });
    }

    // ----- Evaluate Script methods

    protected Promise<Request, ResourceException> evaluateOnRequest(final Context context, final Request request) {
        if (onRequest != null) {
            ScriptEntry scriptEntry = onRequest.getRight();
            if (!scriptEntry.isActive()) {
                return new ServiceUnavailableException(
                        "Failed to execute inactive script: " + onRequest.getRight().getName())
                    .asPromise();
            }
            Script script = populateScript(scriptEntry, context, request);
            try {
                script.eval();
            } catch (Exception e) {
                logger.debug("Filter/{} script {} encountered exception at {}",
                        onRequest.getRight().getName(), onRequest.getLeft(), e);
                ResourceException re = Utils.adapt(e);
                logger.debug("ResourceException detail: " + re.getDetail());
                return re.asPromise();
            }
        }
        return newResultPromise(request);
    }

    public <R extends Response> Promise<R, ResourceException> evaluateOnResponse(final Context context,
            final Request request, final R response) {
        if (onResponse != null) {
            logger.info("Filter response: {}.", context.getId());
            ScriptEntry scriptEntry = onResponse.getRight();
            if (!scriptEntry.isActive()) {
                return new ServiceUnavailableException(
                        "Failed to execute inactive script: " + onResponse.getRight().getName())
                    .asPromise();
            }
            Script script = populateScript(scriptEntry, context, request);
            script.put("response", response);
            try {
                script.eval();
            } catch (Exception e) {
                logger.debug("Filter/{} script {} encountered exception at {}",
                        onResponse.getRight().getName(), onResponse.getLeft(), e);
                ResourceException re = Utils.adapt(e);
                logger.debug("ResourceException detail: " + re.getDetail());
                return re.asPromise();
            }
        }
        return newResultPromise(response);
    }

    public <R extends Response> Promise<R, ResourceException> evaluateOnFailure(final Context context,
            final Request request, final ResourceException error) {
        if (onFailure != null) {
            ScriptEntry scriptEntry = onFailure.getRight();
            if (!scriptEntry.isActive()) {
                return new ServiceUnavailableException(
                        "Failed to execute inactive script: " + onFailure.getRight().getName())
                    .asPromise();
            }
            Script script = populateScript(scriptEntry, context, request);
            script.put("exception", error.includeCauseInJsonValue().toJsonValue().asMap());
            try {
                script.eval();
            } catch (Exception e) {
                logger.debug("Filter/{} script {} encountered exception at {}",
                        onFailure.getRight().getName(), onFailure.getLeft(), e);
                ResourceException re = Utils.adapt(e);
                logger.debug("ResourceException detail: " + re.getDetail());
                return re.asPromise();
            }
        }
        return error.asPromise();
    }

    private Script populateScript(final ScriptEntry scriptEntry, final Context context, final Request request) {
        final Script script = scriptEntry.getScript(context);
        script.put("request", request);
        script.put("context", context);
        return script;
    }
}
