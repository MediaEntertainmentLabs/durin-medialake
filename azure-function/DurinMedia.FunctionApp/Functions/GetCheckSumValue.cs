using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace DurinMedia.FunctionApp.Functions
{
    public static class GetCheckSumValue
    {
        [FunctionName("GetCheckSumValue")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            string connectionString = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONNECTION_STRING");
            string BlobPath = req.Query["BlobPath"];

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            BlobPath = BlobPath ?? data?.BlobPath;

            if (!string.IsNullOrEmpty(connectionString) && !string.IsNullOrEmpty(BlobPath))
            {
                string[] fpArray = BlobPath.Split("/");
                string container = fpArray[0];
                string blobName = BlobPath.Substring(BlobPath.IndexOf('/') + 1);

                BlobServiceClient blobServiceClient = new BlobServiceClient(connectionString);
                BlobContainerClient blobCont = blobServiceClient.GetBlobContainerClient(container);

                BlobClient blobClient = blobCont.GetBlobClient(blobName);
                BlobProperties properties = await blobClient.GetPropertiesAsync();

                byte[] todecode_byte = properties.ContentHash;
                string md5hash = BitConverter.ToString(todecode_byte).Replace("-", "");


                return new OkObjectResult(md5hash);

            }
            else
            {
                return new NotFoundObjectResult("connection string or BlobPath is missing");
            }

        }
    }
}
