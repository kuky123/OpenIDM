/**
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
 * Copyright 2014-2016 ForgeRock AS.
 */

define([
    "jquery",
    "underscore",
    "org/forgerock/openidm/ui/admin/settings/authentication/AuthenticationAbstractView",
    "org/forgerock/commons/ui/common/components/ChangesPending"
], function($, _,
            AuthenticationAbstractView,
            ChangesPending) {

    var SessionModuleView = AuthenticationAbstractView.extend({
        template: "templates/admin/settings/authentication/SessionModuleTemplate.html",
        element: "#sessionModuleView",
        noBaseTemplate: true,
        events: {
            "change .changes-watched": "checkChanges",
            "keyup .changes-watched": "checkChanges"
        },
        data: {
            "properties": {
                "maxTokenLife": "120",
                "tokenIdleTime": "30",
                "sessionOnly": "false"
            }
        },
        model: {},

        /**
         * @param configs {object}
         * @param [callback]
         */
        render: function (configs, callback) {
            this.model = _.extend({},configs,this.getAuthenticationData());

            if (this.model.changes) {
                this.data.sessionModule = this.model.changes;

                // So we don't overwrite our model we only use the changes object once unless reset by undo
                delete this.model.changes;

            } else {
                this.data.sessionModule = _.clone(this.model.sessionModule);
            }

            if (_.has(this.data.sessionModule.properties, "maxTokenLifeSeconds")) {
                this.data.maxTokenLife = this.data.sessionModule.properties.maxTokenLifeSeconds;
                this.data.maxTokenLifeMinutes = false;

            } else if (_.has(this.data.sessionModule.properties, "maxTokenLifeMinutes")) {
                this.data.maxTokenLife = this.data.sessionModule.properties.maxTokenLifeMinutes;
                this.data.maxTokenLifeMinutes = true;
            }

            if (_.has(this.data.sessionModule.properties, "tokenIdleTimeSeconds")) {
                this.data.tokenIdleTime = this.data.sessionModule.properties.tokenIdleTimeSeconds;
                this.data.tokenIdleTimeMinutes = false;

            } else if (_.has(this.data.sessionModule.properties, "tokenIdleTimeMinutes")) {
                this.data.tokenIdleTime = this.data.sessionModule.properties.tokenIdleTimeMinutes;
                this.data.tokenIdleTimeMinutes = true;
            }


            /**
            * TODO handle issue of tokens being replaced => https://bugster.forgerock.org/jira/browse/OPENIDM-5297
            * these properties are being replaced by their clear text values and should be:
            * this.data.sessionModule.properties.keyAlias =  "&{openidm.https.keystore.cert.alias}";
            * this.data.sessionModule.properties.privateKeyPassword =  "&{openidm.keystore.password}";
            * this.data.sessionModule.properties.keystoreType =  "&{openidm.keystore.type}";
            * this.data.sessionModule.properties.keystoreFile =  "&{openidm.keystore.location}";
            * this.data.sessionModule.properties.keystorePassword =  "&{openidm.keystore.password}";
            */

            this.parentRender(_.bind(function() {
                // Watch for changes
                if (!_.has(this.model, "changesModule")) {
                    this.model.changesModule = ChangesPending.watchChanges({
                        element: this.$el.find(".authentication-session-changes"),
                        undo: true,
                        watchedObj: this.model.sessionModule,
                        undoCallback: _.bind(function (original) {
                            this.reRender({changes: original});
                            this.checkChanges();
                        }, this)
                    });
                } else {
                    this.model.changesModule.reRender(this.$el.find(".authentication-session-changes"));
                }

                this.checkChanges();

                if (callback) {
                    callback();
                }
            }, this));
        },

        checkChanges: function(e) {

            _.each(["maxTokenLifeSeconds", "maxTokenLifeMinutes", "tokenIdleTimeSeconds", "tokenIdleTimeMinutes"], _.bind(function(prop) {
                if (_.has(this.data.sessionModule.properties, prop)) {
                    delete this.data.sessionModule.properties[prop];
                }
            }, this));

            this.data.sessionModule.properties.sessionOnly = this.$el.find("#sessionOnly").is(":checked");

            if (this.$el.find("#maxTokenLifeUnits").val() === "seconds") {
                this.data.sessionModule.properties.maxTokenLifeSeconds = this.$el.find("#maxTokenLife").val();
            } else {
                this.data.sessionModule.properties.maxTokenLifeMinutes = this.$el.find("#maxTokenLife").val();
            }

            if (this.$el.find("#tokenIdleTimeUnits").val() === "seconds") {
                this.data.sessionModule.properties.tokenIdleTimeSeconds = this.$el.find("#tokenIdleTime").val();

            } else {
                this.data.sessionModule.properties.tokenIdleTimeMinutes = this.$el.find("#tokenIdleTime").val();
            }

            this.setProperties(["sessionModule"], this.data);
            this.model.changesModule.makeChanges(this.data.sessionModule, true);
        },

        reRender: function(options) {
            this.render(_.extend(this.model, options));
        }
    });

    return new SessionModuleView();
});
