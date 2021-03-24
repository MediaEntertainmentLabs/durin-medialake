namespace Microsoft.Media.DurinMediaLake
{
	using Microsoft.Xrm.Sdk;
	using System;

	public abstract class PluginBase : IPlugin
	{
		protected IOrganizationService OrganizationService { get; set; }
		protected IPluginExecutionContext PluginContext { get; set; }
		protected ITracingService TracingService { get; set; }

		/// <summary>
		/// Execute method that is required by the IPlugin interface.
		/// </summary>
		/// <param name="serviceProvider">The service provider from which you can obtain the
		/// tracing service, plug-in execution context, organization service, and more.</param>
		public void Execute(IServiceProvider serviceProvider)
		{
			if (serviceProvider == null)
			{
				throw new InvalidPluginExecutionException("serviceProvider");
			}

			//Extract the tracing service for use in debugging sandboxed plug-ins.
			this.TracingService = (ITracingService)serviceProvider.GetService(typeof(ITracingService));

			// Obtain the execution context from the service provider.
			this.PluginContext = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));

			// Obtain the organization service reference.
			IOrganizationServiceFactory serviceFactory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
			this.OrganizationService = serviceFactory.CreateOrganizationService(this.PluginContext.UserId);
			try
			{
				this.ExecutePlugin();
			}
			catch(Exception ex)
            {
				this.TracingService.Trace("metadataPlugin: {0}", ex.ToString());
				throw;
			}
		}

		/// <summary>
		/// This will be implemented by drive class
		/// </summary>
		public abstract void ExecutePlugin();
	}
}
