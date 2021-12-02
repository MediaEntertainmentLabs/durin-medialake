using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using Newtonsoft.Json.Linq;

namespace Func_ParseMediaMetadata
{
    public static class ParseMediaMetadata
    {
        [FunctionName("ParseMediaMetadata")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

            MetadataSrc dataSrc = JsonConvert.DeserializeObject<MetadataSrc>(requestBody);

            MetadataTransformed metadataTrans = new MetadataTransformed();
            List<Media> mediaList = new List<Media>();
            List<Type> typeList = null;  
            Media media = null;
            Type type = null;

            foreach (Newtonsoft.Json.Linq.JObject trackSrc in dataSrc.media.track)
            {
                media = new Media();
                typeList = new List<Type>();
                foreach (JProperty property in trackSrc.Children())
                {
                    try
                    {
                        string tokNam = property.Name;
                        string tokVal = (property.Value.Type.Equals(JTokenType.String)) ? (string)property.Value : property.Value.ToString();

                        if ("@type".Equals(tokNam))
                        {
                            media.track = tokVal;
                        }
                        else if ("Format".Equals(tokNam))
                        {
                            media.format = tokVal; 
                        }

                        type = new Type();
                        type.key = tokNam;
                        type.value = tokVal;
                        typeList.Add(type);
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(ex.ToString());
                    }
                }
                media.type = typeList.ToArray();
                mediaList.Add(media);
            }
            metadataTrans.media = mediaList.ToArray();
            string metadataTransStr = JsonConvert.SerializeObject(metadataTrans);

            return new OkObjectResult(metadataTransStr);
        }
    }
}
