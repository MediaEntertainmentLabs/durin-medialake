(function (DurinMedia) {
    var CopyVendorUtility = {};

    CopyVendorUtility.CanCopy = function (selectedRows, selectedcontrol) {
        var entityName = selectedcontrol.getEntityName();
        var viewId = selectedcontrol.getViewSelector().getCurrentView().id;
        switch (entityName) {
            case "media_assetfiles":
                return viewId == '{B8244684-9944-4CBB-AB4C-24D05FC22600}';
            case "media_asset":
                return viewId == '{63F62624-A771-4C0C-B73E-D0747AC7E221}'
            default:
                return false;
        }
    }

    CopyVendorUtility.ShowVendorDialog = function (selectedRows, selectedcontrol) {
        CopyVendorUtility.openCommonDialog(selectedRows, selectedcontrol, 'vendor');
    }

    CopyVendorUtility.openCommonDialog = function (selectedRows, selectedcontrol, copyType) {
        var selectedIds = selectedRows.map(x => x.Id);
        CopyVendorUtility.CheckIfMultipleShowSelected(selectedcontrol.getEntityName(), selectedcontrol.getFetchXml(), selectedIds)
            .then((res) => {
                if (!res.isMultipleShowSelected) {
                    Xrm.Navigation.openDialog("CopyToVendorDialog", { height: 300, width: 400 },
                        {
                            media_entityName: selectedcontrol.getEntityName(),
                            media_entities: JSON.stringify(res.selectedSources),
                            media_showId: res.showId,
                            media_type: copyType
                        });
                }
                else {
                    CopyVendorUtility.showErrorMessage("Please select record for the same show");
                }
            })
    }

    CopyVendorUtility.showErrorMessage = function (msg) {
        Xrm.Navigation.openErrorDialog({ message: msg });
    }

    CopyVendorUtility.CheckIfMultipleShowSelected = function (entity, fetchXml, selectedIds) {
        return new Promise((res, rej) => {
            var apiUrl = '';
            var showColumnName = '';
            switch (entity) {
                case "media_asset":
                    {
                        apiUrl = `/api/data/v9.1/media_assets?fetchXml=${fetchXml}`;
                        showColumnName = '_media_assetcontainer_value';

                    } break;
                case "media_season": {
                    apiUrl = `/api/data/v9.1/media_seasons?fetchXml=${fetchXml}`;
                    showColumnName = "_media_show_value";
                } break;
                case "media_assetfiles": {
                    apiUrl = `/api/data/v9.1/media_assetfileses?fetchXml=${fetchXml}`;
                    showColumnName = "media_asset.media_assetcontainer";
                } break;
            }

            fetch(Xrm.Utility.getGlobalContext().getClientUrl() + apiUrl).then((response) => response.json()).then(data => {
                var showid = '';
                var isMultipleShowSelected = false;
                var selectedSources = [];
                for (index = 0; index < data.value.length; index++) {
                    var etn = data.value[index];
                    var etnid = etn[`${entity}id`];
                    var assetContainerId = etn[showColumnName];
                    if (selectedIds.indexOf(etnid) >= 0) { // selected record
                        if (showid != '' && showid != assetContainerId) {
                            isMultipleShowSelected = true
                            break;
                        } else {
                            showid = assetContainerId;
                        }
                        selectedSources.push({
                            id: etnid,
                            name: etn['media_name'],
                            path: etn['media_blobpath'],
                            aleId: etn['media_alefileid'] || ''
                        })
                    }
                }
                res({ showId: showid, isMultipleShowSelected, selectedSources });
            });
        });
    }

    CopyVendorUtility.GetVendorList = function () {
        var showId = parent.Xrm.Page.getAttribute('media_showId').getValue();
        return fetch(parent.Xrm.Utility.getGlobalContext().getClientUrl() + `/api/data/v9.1/media_showvendormappings?$select=media_name&$expand=media_Vendor($select=media_name,media_folderpath)&$filter=_media_show_value eq ${showId}`).then(res => res.json())
    }

    CopyVendorUtility.GetNexisList = function () {
        var showId = parent.Xrm.Page.getAttribute('media_showId').getValue();
        return fetch(parent.Xrm.Utility.getGlobalContext().getClientUrl() + `/api/data/v9.1/media_shownexismappings?$select=media_name&$expand=media_Nexis($select=media_name,media_linkedservicename)&$filter=_media_show_value eq ${showId}`).then(res => res.json())
    }

    CopyVendorUtility.OnDialogOk = function (formContext) {

        var type = formContext.getFormContext().getAttribute('media_type').getValue();
        var showId = formContext.getFormContext().getAttribute('media_showId').getValue();
        var entityName = formContext.getFormContext().getAttribute('media_entityName').getValue();
        var source = formContext.getFormContext().getAttribute('media_entities').getValue();
        var destination = formContext.getFormContext().getAttribute('media_selectedLocation').getValue();
        var userId = formContext.getContext().userSettings.userId.replace(/[{}]/g, '');

        if (source && destination) {
            source = JSON.parse(source);
            destination = JSON.parse(destination);
            var orgUrl = Xrm.Utility.getGlobalContext().getClientUrl();
            Promise.all([
                fetch(orgUrl + `/api/data/v9.1/media_assetcontainers(${showId})/media_containerpath`).then(res => res.json()),
                fetch(orgUrl + `/api/data/v9.1/systemusers(${userId})/internalemailaddress`).then(res => res.json())
            ]).then((responses) => {
                var containerName = responses[0].value;
                if (entityName == 'media_season') {
                    source.forEach(y => {
                        y.path = `${containerName}/${y.name}`;
                    })
                }
                var request = {
                    destination: destination,
                    source: source,
                    showid: showId,
                    container: containerName,
                    entityLogicalName: entityName,
                    destinationType: type,
                    submittedBy: {
                        userId: userId,
                        email: responses[1].value
                    }
                }

                Xrm.WebApi.createRecord("media_copyrequest", {
                    media_data: JSON.stringify(request)
                }).then(
                    function success(result) {
                        Xrm.Page.ui.close();
                        Xrm.App.addGlobalNotification({
                            type: 1,
                            level: 1,
                            message: "Copy request queued."
                        }).then(
                            function success(result) {

                            },
                            function (error) {
                                console.log(error.message);
                                // handle error conditions
                            }
                        );

                    },
                    function (error) {
                        console.log(error.message);
                        // handle error conditions
                    }
                );

            })
        }
        else
            Xrm.Page.ui.close();

    }
    CopyVendorUtility.OnDialogCancel = function (formContext) {
        Xrm.Page.ui.close();
    }

    CopyVendorUtility.CopyToNexis = function (selectedRows, selectedcontrol) {
        CopyVendorUtility.openCommonDialog(selectedRows, selectedcontrol, 'nexis');
    }

    DurinMedia.CopyVendorUtility = CopyVendorUtility;
})(window.DurinMedia = window.DurinMedia || {})