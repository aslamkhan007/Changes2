using CEI_PRoject;

namespace CEIHaryana.Industry_Master.Services
{
    public class IndustryBasicCafProcessor : IIndustryBasicCafProcessor
    {
        private readonly CEI cei;

        public IndustryBasicCafProcessor()
        {
            cei = new CEI();
        }
        public void ProcessFromStoredProcedure(string storedProcedureName, string cafPinColumnName = "cafPin")
        {
            cei.GetIndustryBasicCafDetailsFromSp(storedProcedureName, cafPinColumnName);
        }
    }
}
