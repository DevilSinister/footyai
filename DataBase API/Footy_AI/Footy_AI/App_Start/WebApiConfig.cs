using System.Web.Http;
using System.Web.Http.Cors;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Footy_AI
{
    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // CORS
            var cors = new EnableCorsAttribute(
                origins: "*",
                headers: "*",
                methods: "*");

            config.EnableCors(cors);

            // JSON formatting
            var json = config.Formatters.JsonFormatter;

            json.SerializerSettings.ContractResolver =
                new CamelCasePropertyNamesContractResolver();

            json.SerializerSettings.NullValueHandling =
                NullValueHandling.Ignore;

            // Always return JSON
            config.Formatters.Remove(config.Formatters.XmlFormatter);

            // URL-based routing
            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{action}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );
        }
    }
}