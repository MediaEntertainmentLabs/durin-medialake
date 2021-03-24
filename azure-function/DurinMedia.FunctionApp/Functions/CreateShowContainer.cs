namespace DurinMedia.FunctionApp.Functions
{
    using System;
    using System.IO;
    using System.Text;
    using System.Threading.Tasks;
    using Azure.Storage.Blobs;
    using Microsoft.AspNetCore.Http;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Azure.WebJobs;
    using Microsoft.Azure.WebJobs.Extensions.Http;
    using Microsoft.Extensions.Logging;
    using Newtonsoft.Json;

    public static class CreateShowContainer
    {
        [FunctionName("CreateShowContainer")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            string connectionString = string.Empty;
            string name = req.Query["name"];
            string type = req.Query["type"];

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            name = name ?? data?.name;
            type = type ?? data?.type;

            if (!string.IsNullOrEmpty(type) && type.ToLower() == "vendor")
            {
                connectionString = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONNECTION_STRING_VENDOR");
            }
            else
            {
                connectionString = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONNECTION_STRING");
            }

            //Create a unique name for the container
            string containerName = name;
            if (!string.IsNullOrEmpty(connectionString) && !string.IsNullOrEmpty(containerName))
            {
                containerName = CreateShowContainer.RemoveSpecialCharacters(containerName).ToLower();

                // Create a BlobServiceClient object which will be used to create a container client
                BlobServiceClient blobServiceClient = new BlobServiceClient(connectionString);

                // Create the container and return a container client object
                BlobContainerClient containerClient = await blobServiceClient.CreateBlobContainerAsync(containerName);

                return new OkObjectResult(containerName);
            }
            else
            {
                return new NotFoundObjectResult("connection string or name is missing");
            }
        }

        /// <summary>
        /// Remove special charcter from string, only number and camel case are allowed
        /// </summary>
        /// <param name="str"></param>
        /// <returns></returns>
        public static string RemoveSpecialCharacters(string str)
        {
            StringBuilder sb = new StringBuilder();
            foreach (char c in str)
            {
                if ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '-')
                {
                    sb.Append(c);
                }
            }
            return sb.ToString();
        }
    }
}
