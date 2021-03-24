namespace Microsoft.Media.DurinMediaLake.Plugin
{
    using Microsoft.Crm.Sdk.Messages;
    using Microsoft.Media.DurinMediaLake.Constant;
    using Microsoft.Xrm.Sdk;
    using Microsoft.Xrm.Sdk.Query;
    using System;

    public class UpdateAssetUploadStatus : PluginBase
    {
        public override void ExecutePlugin()
        {
            if (this.PluginContext.InputParameters.Contains(PluginConstants.Target) &&
                PluginContext.InputParameters[PluginConstants.Target] is Entity)
            {
                // Obtain the target entity from the input parameters.
                Entity fileEntity = (Entity)this.PluginContext.InputParameters[PluginConstants.Target];

                // Verify that the target entity represents the media_assetfiles.
                // If not, this plug-in was not registered correctly.
                if (fileEntity.LogicalName != MediaAssetFileConstants.EntityLogicalName)
                    return;

                Entity mediaassetfile = this.OrganizationService.Retrieve(MediaAssetFileConstants.EntityLogicalName, fileEntity.Id, new ColumnSet(true));
                EntityReference accountRef = mediaassetfile.GetAttributeValue<EntityReference>(MediaAssetConstants.EntityLogicalName);
                Entity mediasset = this.OrganizationService.Retrieve(MediaAssetConstants.EntityLogicalName, accountRef.Id, new ColumnSet(MediaAssetConstants.FolderFileCount));

                CalculateRollupFieldRequest rollupRequest = new CalculateRollupFieldRequest { Target = new EntityReference(MediaAssetConstants.EntityLogicalName, mediasset.Id), FieldName = MediaAssetConstants.UploadedFile };
                CalculateRollupFieldResponse response = (CalculateRollupFieldResponse)this.OrganizationService.Execute(rollupRequest);

                if(fileEntity.Contains(MediaAssetFileConstants.Status))
                {
                    if(Convert.ToInt32(((Microsoft.Xrm.Sdk.OptionSetValue)fileEntity.Attributes[MediaAssetFileConstants.Status]).Value) == 1)
                    {
                        var query = new QueryExpression();
                        query.EntityName = MediaAssetFileConstants.EntityLogicalName;
                        query.ColumnSet = new ColumnSet("media_name");
                        query.Criteria.AddCondition(MediaAssetConstants.EntityLogicalName, ConditionOperator.Equal, mediasset.Id);
                        query.Criteria.AddCondition(MediaAssetFileConstants.Status, ConditionOperator.Equal, 0);

                        var assetFiles = this.OrganizationService.RetrieveMultiple(query).Entities; 

                        mediasset.Attributes[MediaAssetConstants.FolderFileCount] = assetFiles?.Count;
                        if(Convert.ToInt32(response.Entity.Attributes[MediaAssetConstants.UploadedFile]) == 0)
                        {
                            mediasset.Attributes[MediaAssetConstants.AssetStatus] = new OptionSetValue(UploadStatus.Started);
                        }
                        this.OrganizationService.Update(mediasset);
                    }
                }   

                if (fileEntity.Contains(MediaAssetFileConstants.UploadStatus))
                {
                    var uploadStatus = ((Microsoft.Xrm.Sdk.OptionSetValue)fileEntity.Attributes[MediaAssetFileConstants.UploadStatus]).Value;
                    //Get count of Uploaded Asset files in an Asset
                    int AssetFolderFileCount = Convert.ToInt32((mediasset.Attributes[MediaAssetConstants.FolderFileCount]));

                    if (AssetFolderFileCount == Convert.ToInt32(response.Entity.Attributes[MediaAssetConstants.UploadedFile]))
                    {
                        mediasset.Attributes[MediaAssetConstants.AssetStatus] = new OptionSetValue(UploadStatus.Completed);
                        this.OrganizationService.Update(mediasset);
                    }
                    else if(uploadStatus!= UploadStatus.PartiallyUpload)
                    {
                        mediasset.Attributes[MediaAssetConstants.AssetStatus] = new OptionSetValue(UploadStatus.PartiallyUpload);
                        this.OrganizationService.Update(mediasset);
                    }
                    
                }
            }
        }
    }
}
