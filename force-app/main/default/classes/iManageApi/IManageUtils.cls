public with sharing class IManageUtils {
    public static List<Object> reverseList(List<Object> lst) {
        List<Object> reversed = new List<Object>();

        for(Integer i = lst.size() - 1; i >= 0; i--){
            reversed.add(lst[i]);
        }

        return reversed;
    }
}