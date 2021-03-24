namespace Microsoft.Media.DurinMediaLake.Plugin
{
    using Microsoft.Media.DurinMediaLake.Constant;
    using Microsoft.Xrm.Sdk;
    using Microsoft.Xrm.Sdk.Query;
    using Newtonsoft.Json;
    using System;
    using System.Collections.Generic;
    using System.Linq;
    public class CameraMetadataExtraction : PluginBase
    {
        public override void ExecutePlugin()
        {
            if (this.PluginContext.InputParameters.Contains(PluginConstants.Target) && this.PluginContext.InputParameters[PluginConstants.Target] is Entity)
            {
                //var asset = this.PluginContext.InputParameters[PluginConstants.Target] as Entity;
                var assetfiles = this.PluginContext.InputParameters[PluginConstants.Target] as Entity;
                this.TracingService.Trace("CameraRaw Plugin: Run Started for Id - " + assetfiles.Id);
                if (assetfiles != null && assetfiles.Attributes != null && assetfiles.Attributes.ContainsKey(MediaAssetFileConstants.AlefileContent))
                {
                    this.TracingService.Trace("CameraRaw Plugin Ale: Run Started for Id - " + assetfiles.Id);
                    var cameraFileMetatdata = Convert.ToString(assetfiles.Attributes[MediaAssetFileConstants.AlefileContent]);

                    Entity mediaassetfile = this.OrganizationService.Retrieve(MediaAssetFileConstants.EntityLogicalName, assetfiles.Id, new ColumnSet(true));
                    EntityReference assetRef = mediaassetfile.GetAttributeValue<EntityReference>(MediaAssetConstants.EntityLogicalName);
                    Entity mediasset = this.OrganizationService.Retrieve(MediaAssetConstants.EntityLogicalName, assetRef.Id, new ColumnSet("media_assetid"));

                    string BlobPath = Convert.ToString(mediaassetfile.Attributes[MediaAssetFileConstants.BlobPath]);
                    string containsPath = BlobPath.Substring(0, BlobPath.LastIndexOf("/"));

                    var assetid = Convert.ToString(mediasset.Attributes["media_assetid"]);
                    if (!string.IsNullOrEmpty(cameraFileMetatdata))
                    {
                        var query = new QueryExpression();
                        query.EntityName = MediaAssetFileConstants.EntityLogicalName;
                        query.ColumnSet = new ColumnSet("media_name");
                        query.Criteria.AddCondition(MediaAssetConstants.EntityLogicalName, ConditionOperator.Equal, assetid);
                        query.Criteria.AddCondition(MediaAssetFileConstants.Status, ConditionOperator.Equal, 0);
                        query.Criteria.AddCondition(MediaAssetFileConstants.BlobPath, ConditionOperator.Like, containsPath + "%");

                        var assetFiles = this.OrganizationService.RetrieveMultiple(query).Entities;
                        if (assetFiles.Count > 0)
                        {
                            var lines = cameraFileMetatdata.Split('\n');

                            int columnLineNo = -1;
                            int dataStartFromLineNo = -1;
                            var columns = new List<string>();
                            for (int lineno = 0; lineno < lines.Length; lineno++)
                            {
                                if (string.IsNullOrWhiteSpace(lines[lineno]))
                                    continue;
                                var line = lines[lineno];
                                if (Convert.ToString(line).Trim('\t') == "Column")
                                {
                                    columnLineNo = lineno + 1;
                                }
                                if (Convert.ToString(line).Trim('\t') == "Data")
                                {
                                    dataStartFromLineNo = lineno + 1;
                                    continue;
                                }

                                if (lineno == columnLineNo)
                                {
                                    columns.AddRange(line.Split('\t'));
                                }
                                else if (dataStartFromLineNo > -1 && dataStartFromLineNo <= lineno)
                                {
                                    var assetfileid = string.Empty;
                  
                                    var data = line.Split('\t');

                                    Dictionary<string, string> attrdict = new Dictionary<string, string>();
                                    MiscInfo miscInfo = new MiscInfo();
                                    miscInfo = JsonConvert.DeserializeObject<MiscInfo>(mediaassetfile.Attributes[MediaAssetFileConstants.miscInfo].ToString());

                                    for (int columnindex = 0; columnindex < columns.Count; columnindex++)
                                    {
                                        attrdict.Add(columns[columnindex], data[columnindex]);
                                        if (columns[columnindex] == miscInfo.AleFileNameField)
                                        {
                                            if (miscInfo.MatchType == "Exact Match")
                                            {
                                                var assetfile = assetFiles.Where(x => Convert.ToString(x.Attributes["media_name"]).ToLower() == data[columnindex].ToLower() || Convert.ToString(x.Attributes["media_name"]).Substring(0, Convert.ToString(x.Attributes["media_name"]).LastIndexOf(".")).ToLower() == data[columnindex].ToLower()).FirstOrDefault();
                                                if (assetfile != null)
                                                {
                                                    assetfile["media_alefileid"] = Convert.ToString(assetfiles.Attributes["media_assetfilesid"]);
                                                    this.OrganizationService.Update(assetfile);
                                                    assetfileid = Convert.ToString(assetfile.Attributes["media_assetfilesid"]);
                                                }
                                            }
                                            else
                                            {
                                                var truncatedFAleFileNameField = (data[columnindex].Substring(miscInfo.TruncateCharFromStart, (data[columnindex].Length) - miscInfo.TruncateCharFromEnd - miscInfo.TruncateCharFromStart)).ToLower();
                                                var assetfile = assetFiles.Where(x => Convert.ToString(x.Attributes["media_name"]).ToLower() == truncatedFAleFileNameField || Convert.ToString(x.Attributes["media_name"]).Substring(0, Convert.ToString(x.Attributes["media_name"]).LastIndexOf(".")).ToLower() == truncatedFAleFileNameField).FirstOrDefault();
                                                if (assetfile != null)
                                                {
                                                    assetfile["media_alefileid"] = Convert.ToString(assetfiles.Attributes["media_assetfilesid"]);
                                                    this.OrganizationService.Update(assetfile);
                                                    assetfileid = Convert.ToString(assetfile.Attributes["media_assetfilesid"]);
                                                }
                                            }
                                        }
                                    }

                                    if (!string.IsNullOrEmpty(assetfileid))
                                    {
                                        foreach (string key in attrdict.Keys)
                                        {
                                            try
                                            {
                                                var entity = new Entity(MetadataConstants.CameraMetadataEntityLogicalName);
                                                entity.Attributes.Add("media_keyname", key);
                                                entity.Attributes.Add("media_keyvalue", attrdict[key]);
                                                entity.Attributes.Add(MediaAssetFileConstants.EntityLogicalName, new EntityReference(MediaAssetFileConstants.EntityLogicalName, Guid.Parse(assetfileid)));
                                                this.OrganizationService.Create(entity);
                                            }
                                            catch (Exception e)
                                            {
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
