public with sharing class GridData
{
    @AuraEnabled
    public List<Map<String, Object>> Data;

    @AuraEnabled
    public Integer Total;

    @AuraEnabled
    public Boolean HasNext;

    public GridData(List<Map<String, Object>> data, Integer total, Boolean hasNext)
    {
        this.Data = data;
        this.Total = total;
        this.HasNext = hasNext;
    }
}