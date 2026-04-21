using CEIHaryana.Industry_Master.Services;
using System;
using System.Web.UI;

namespace CEIHaryana.Industry
{
    public partial class BasicCafDetails_Scheduler : System.Web.UI.Page
    {
        private readonly IIndustryBasicCafProcessor basicCafProcessor = new IndustryBasicCafProcessor();

        private const string CafSourceStoredProcedureName = "sp_Industry_GetCafPinList_ForBasicCafDetails";
        private const string FailedCafSourceStoredProcedureName ="sp_Industry_GetFailedCafPinList_ForBasicCafDetails";
        private const string CafPinColumnName = "cafPin";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                string mode = Request.QueryString["mode"];

                if (mode == "failed")
                    ProcessFailedCafDetails();
                else
                    ProcessBasicCafDetails();
                hfTaskCompleted.Value = "true";
            }
        }

        private void ProcessBasicCafDetails()
        {
            try
            {
                basicCafProcessor.ProcessFromStoredProcedure(CafSourceStoredProcedureName, CafPinColumnName);
            }
            catch (Exception ex)
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(), "showalert", $"alert('{ex.Message}')", true);
            }
        }
        private void ProcessFailedCafDetails()
        {
            try
            {
                basicCafProcessor.ProcessFromStoredProcedure(FailedCafSourceStoredProcedureName, CafPinColumnName);
            }
            catch (Exception ex)
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(),"showalert", $"alert('{ex.Message}')", true);
            }
        }
    }
}
