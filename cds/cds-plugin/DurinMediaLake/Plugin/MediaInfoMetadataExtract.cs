namespace Microsoft.Media.DurinMediaLake.Plugin
{
    using Microsoft.Media.DurinMediaLake.Constant;
    using Microsoft.Media.DurinMediaLake.Models;
    using Microsoft.Xrm.Sdk;
    using Microsoft.Xrm.Sdk.Messages;
    using Newtonsoft.Json;
    using System;
    using System.Linq;

    public class MediaInfoMetadataExtract : PluginBase
    {
        public override void ExecutePlugin()
        {
            try
            {
                // The InputParameters collection contains all the data passed in the message request.
                if (this.PluginContext.InputParameters.Contains(PluginConstants.Target) &&
                    PluginContext.InputParameters[PluginConstants.Target] is Entity)
                {
                    // Obtain the target entity from the input parameters.
                    Entity fileEntity = (Entity)this.PluginContext.InputParameters[PluginConstants.Target];

                    // Verify that the target entity represents the media_assetfiles.
                    // If not, this plug-in was not registered correctly.
                    if (fileEntity.LogicalName != MediaAssetFileConstants.EntityLogicalName)
                        return;

                    string rawMetadataJson = String.Empty;
                    MediaInfoMetadata mediaInfoMetadata = new MediaInfoMetadata();

                    this.TracingService.Trace("MediaInfoMetadataExtraction Plugin: Run Started for Id - " + fileEntity.Id);

                    if (fileEntity.Contains(MediaAssetFileConstants.MediaInfoMetadata))
                    {
                        rawMetadataJson = fileEntity.GetAttributeValue<string>(MediaAssetFileConstants.MediaInfoMetadata).Replace("\"@type\":", "\"TrackType\":");
                        mediaInfoMetadata = JsonConvert.DeserializeObject<MediaInfoMetadata>(rawMetadataJson);


                        if (mediaInfoMetadata.media.track.Length > 0)
                        {
                            var mediaTracks = mediaInfoMetadata.media.track;
                            int totalMetadataCount = 0;
                            int failedMetadataCount = 0;

                            foreach (Track track in mediaTracks)
                            {
                                // Create an entry in mediatrack
                                Entity mediaTrack = new Entity(MediaTrackConstants.EntityLogicalName);

                                // Create an ExecuteMultipleRequest object.
                                var requestWithResults = new ExecuteMultipleRequest()
                                {
                                    // Assign settings that define execution behavior: continue on error, return responses. 
                                    Settings = new ExecuteMultipleSettings()
                                    {
                                        ContinueOnError = true,
                                        ReturnResponses = true
                                    },
                                    // Create an empty organization request collection.
                                    Requests = new OrganizationRequestCollection()
                                };

                                mediaTrack[MediaTrackConstants.Type] = track.TrackType;
                                mediaTrack[MediaTrackConstants.Format] = track.Format;

                                // Reference to the asset file in the track record.
                                if (this.PluginContext.PrimaryEntityId != Guid.Empty)
                                {
                                    Guid regardingobjectid = new Guid(this.PluginContext.PrimaryEntityId.ToString());
                                    string regardingobjectidType = MediaAssetFileConstants.EntityLogicalName;

                                    mediaTrack[MediaTrackConstants.RefAssetFile] = new EntityReference(regardingobjectidType, regardingobjectid);
                                }

                                Guid mediaTrackId = this.OrganizationService.Create(mediaTrack);

                                if (mediaTrackId != Guid.Empty)
                                {
                                    totalMetadataCount += track.ExtensionData.Count;

                                    foreach (var data in track.ExtensionData)
                                    {
                                        // Create an entry in metadata
                                        Entity metadata = new Entity(MetadataConstants.EntityLogicalName);

                                        metadata[MetadataConstants.KeyName] = data.Key;
                                        metadata[MetadataConstants.KeyValue] = (data.Value is string) ? data.Value : JsonConvert.SerializeObject(data.Value);

                                        // Reference to the track in the metadata record.
                                        Guid regardingobjectid = mediaTrackId;
                                        string regardingobjectidType = MetadataConstants.RefTrack;

                                        metadata[MetadataConstants.RefTrack] = new EntityReference(regardingobjectidType, regardingobjectid);

                                        //Guid media_metadata = OrganizationService.Create(metadata);

                                        #region Execute Multiple with Results

                                        // Create several (local, in memory) entities in a collection. 
                                        EntityCollection input = new EntityCollection();
                                        input.Entities.Add(metadata);

                                        CreateRequest createRequest = new CreateRequest { Target = input[0] };
                                        requestWithResults.Requests.Add(createRequest);

                                        #endregion
                                    }

                                    // Execute all the requests in the request collection using a single web method call.
                                    ExecuteMultipleResponse responseWithResults =
                                        (ExecuteMultipleResponse)this.OrganizationService.Execute(requestWithResults);

                                    failedMetadataCount += responseWithResults.Responses.Where(x => x.Fault != null).Count();
                                }
                                else
                                {
                                    this.TracingService.Trace("MediaInfoMetadataExtraction: mediaTrackId is empty.");
                                }
                            }

                            this.TracingService.Trace(string.Format("MediaInfoMetadataExtraction: Successfully created {0}/{1} metadata record related to asset file.", totalMetadataCount - failedMetadataCount, totalMetadataCount));
                            this.TracingService.Trace(string.Format("MediaInfoMetadataExtraction: {0} metadata record failed", failedMetadataCount));
                        }
                        else
                        {
                            this.TracingService.Trace("MediaInfoMetadataExtraction: metadata extracted from media info don't have any track.");
                        }

                        // Create the task in Microsoft Dynamics CRM.
                        this.TracingService.Trace("MediaInfoMetadataExtraction: Run Completed");
                    }
                }
            }
            catch (Exception ex)
            {
                this.TracingService.Trace("MediaInfoMetadataExtraction: Run Failed | " + ex.Message);
            }
        }

        public void SetFileType(Track[] mediaTracks, Entity fileEntity)
        {
            bool containsAudio = mediaTracks.Any(x => x.TrackType == "Audio");
            bool containsVideo = mediaTracks.Any(x => x.TrackType == "Video");
            bool containsImage = mediaTracks.Any(x => x.TrackType == "Image");

            if (containsAudio)
            {
                if (containsVideo)
                {
                    // set status to Video
                    fileEntity["media_filetype"] = new OptionSetValue((int)FileType.Video);
                }
                else
                {
                    // set status to audio
                    fileEntity["media_filetype"] = new OptionSetValue((int)FileType.Audio);
                }
            }
            else
            {
                if (containsImage)
                {
                    // set status to image
                    fileEntity["media_filetype"] = new OptionSetValue((int)FileType.Image);
                }
                else
                {
                    // set status to other
                    fileEntity["media_filetype"] = new OptionSetValue((int)FileType.Other);
                }
            }

            this.OrganizationService.Update(fileEntity);
        }
    }
}
