using CEIHaryana.Contractor;
using CEIHaryana.Model.Industry;
using iTextSharp.text.pdf.parser;
using Newtonsoft.Json;
using Pipelines.Sockets.Unofficial.Arenas;
using QRCoder;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Net.Sockets;
using System.Text;
using System.Web;
using System.Web.Helpers;
using System.Web.Services.Description;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Media.TextFormatting;
using static System.Net.WebRequestMethods;

namespace CEI_PRoject
{

    public class CEI
    {
        private int tCounter = 1;
        private int lCounter = 1;
        private SqlParameter outputParam;


 public Industry_BasicCafDetails_Model GetIndustryBasicCafDetails(string cafPin)
        {
            if (string.IsNullOrWhiteSpace(cafPin))
            {
                return null;
            }

            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            string endpoint = BuildBasicCafDetailsEndpoint(cafPin);
            Industry_Api_Post_DataformatModel tokenContext = new Industry_Api_Post_DataformatModel
            {
                PremisesType = "Industry",
                InspectionId = 0,
                InspectionLogId = 0,
                IncomingJsonId = 0,
                ActionTaken = "GetBasicCafDetails",
                CommentByUserLogin = "Scheduler",
                CommentDate = DateTime.Now,
                Comments = "basicCafDetails token request",
                Id = cafPin.Trim(),
                ProjectId = null,
                ServiceId = null
            };
            string accessToken = TokenManagerConst.GetAccessToken(tokenContext);

            using (WebClient client = new WebClient())
            {
                client.Headers[HttpRequestHeader.Accept] = "application/json";
                client.Headers[HttpRequestHeader.Authorization] = "Bearer " + accessToken;
                string response = client.DownloadString(endpoint);
                return JsonConvert.DeserializeObject<Industry_BasicCafDetails_Model>(response);
            }
        }

        public List<Industry_BasicCafDetails_Model> GetIndustryBasicCafDetailsFromSp(string storedProcedureName, string cafPinColumnName = "cafPin")
        {
            List<Industry_BasicCafDetails_Model> cafDetailsList = new List<Industry_BasicCafDetails_Model>();

            if (string.IsNullOrWhiteSpace(storedProcedureName))
            {
                return cafDetailsList;
            }

            DataTable cafPinTable = DBTask.ExecuteDataTable(
                ConfigurationManager.ConnectionStrings["DBConnection"].ToString(),
                storedProcedureName
            );

            if (cafPinTable == null || cafPinTable.Rows.Count == 0 || !cafPinTable.Columns.Contains(cafPinColumnName))
            {
                return cafDetailsList;
            }

            foreach (DataRow row in cafPinTable.Rows)
            {
                string cafPin = Convert.ToString(row[cafPinColumnName]);
                if (string.IsNullOrWhiteSpace(cafPin))
                {
                    continue;
                }

                try
                {
                    Industry_BasicCafDetails_Model cafDetails = GetIndustryBasicCafDetails(cafPin);
                    if (cafDetails != null)
                    {
                        bool isHistoryChanged = SaveIndustryBasicCafDetailsHistory(cafDetails);
                        if (isHistoryChanged)
                        {
                            UpdateIndustryBasicCafProcessStatus(cafPin, 1);
                        }
                        cafDetailsList.Add(cafDetails);
                    }
                    else
                    {
                        UpdateIndustryBasicCafProcessStatus(cafPin, 0);
                        LogIndustryBasicCafDetailsError(cafPin, BuildBasicCafDetailsEndpoint(cafPin), "API response was null.", null);
                    }
                }
                catch (Exception ex)
                {
                    UpdateIndustryBasicCafProcessStatus(cafPin, 0);
                    LogIndustryBasicCafDetailsError(cafPin, BuildBasicCafDetailsEndpoint(cafPin), ex.Message, ex.StackTrace);
                    continue;
                }
            }

            return cafDetailsList;
        }

        public bool SaveIndustryBasicCafDetailsHistory(Industry_BasicCafDetails_Model cafDetails)
        {
            if (cafDetails == null || string.IsNullOrWhiteSpace(cafDetails.CafPin))
            {
                return false;
            }

            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["DBConnection"].ToString()))
            using (SqlCommand command = new SqlCommand("sp_UpsertIndustryBasicCafDetailsHistory", connection))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@CurrentBusinessEntity", (object)cafDetails.BusinessEntity ?? DBNull.Value);
                command.Parameters.AddWithValue("@CurrentBusinessEntityType", (object)cafDetails.BusinessEntityType ?? DBNull.Value);
                command.Parameters.AddWithValue("@CurrentSiteAddress", (object)cafDetails.SiteAddress ?? DBNull.Value);
                command.Parameters.AddWithValue("@CurrentDistrict", (object)cafDetails.District ?? DBNull.Value);
                command.Parameters.AddWithValue("@CurrentBlock", (object)cafDetails.Block ?? DBNull.Value);
                command.Parameters.AddWithValue("@CurrentVillage", (object)cafDetails.Village ?? DBNull.Value);
                command.Parameters.AddWithValue("@CurrentCafPin", (object)cafDetails.CafPin ?? DBNull.Value);
                command.Parameters.AddWithValue("@CurrentCafType", (object)cafDetails.CafType ?? DBNull.Value);
                SqlParameter isHistoryChangedParam = new SqlParameter("@IsHistoryChanged", SqlDbType.Bit)
                {
                    Direction = ParameterDirection.Output
                };
                command.Parameters.Add(isHistoryChangedParam);

                connection.Open();
                command.ExecuteNonQuery();

                return isHistoryChangedParam.Value != DBNull.Value && Convert.ToBoolean(isHistoryChangedParam.Value);
            }
        }

        private string BuildBasicCafDetailsEndpoint(string cafPin)
        {
            string basicCafDetailsBaseUrl = ConfigurationManager.AppSettings["IndustryBasicCafDetailsApiBaseUrl"];
            if (string.IsNullOrWhiteSpace(basicCafDetailsBaseUrl))
            {
                basicCafDetailsBaseUrl = "https://investharyana";
            }

            string normalizedBaseUrl = basicCafDetailsBaseUrl.TrimEnd('/');
            if (!normalizedBaseUrl.Contains(".in"))
            {
                normalizedBaseUrl = normalizedBaseUrl + ".in";
            }

            return $"{normalizedBaseUrl}/api/basicCafDetails/{HttpUtility.UrlEncode((cafPin ?? string.Empty).Trim())}";
        }

        public void UpdateIndustryBasicCafProcessStatus(string cafPin, byte processStatus)
        {
            if (string.IsNullOrWhiteSpace(cafPin))
            {
                return;
            }

            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["DBConnection"].ToString()))
            using (SqlCommand command = new SqlCommand("sp_UpsertIndustryBasicCafProcessStatus", connection))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@CafPin", cafPin.Trim());
                command.Parameters.AddWithValue("@ProcessStatus", processStatus);

                connection.Open();
                command.ExecuteNonQuery();
            }
        }

        public void LogIndustryBasicCafDetailsError(string cafPin, string endpointUrl, string errorMessage, string stackTrace)
        {
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["DBConnection"].ToString()))
            using (SqlCommand command = new SqlCommand("sp_LogIndustryBasicCafDetailsError", connection))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@CafPin", (object)cafPin ?? DBNull.Value);
                command.Parameters.AddWithValue("@EndpointUrl", (object)endpointUrl ?? DBNull.Value);
                command.Parameters.AddWithValue("@ErrorMessage", (object)errorMessage ?? DBNull.Value);
                command.Parameters.AddWithValue("@StackTrace", (object)stackTrace ?? DBNull.Value);

                connection.Open();
                command.ExecuteNonQuery();
            }
        }


       

    }
}


