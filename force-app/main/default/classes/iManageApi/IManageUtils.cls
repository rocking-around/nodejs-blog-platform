public with sharing class IManageUtils {
  public static List<Object> reverseList(List<Object> lst) {
    List<Object> reversed = new List<Object>();

    for (Integer i = lst.size() - 1; i >= 0; i--) {
      reversed.add(lst[i]);
    }

    return reversed;
  }

  public static Map<String, Object> removeNullItemsFromMap(Map<String, Object> source, Set<String> ignore) {
    List<String> ignoreKeys = new List<String>(ignore);
    Set<String> mapKeysToRemoveSet = new Set<String>();
    for(String key :source.keySet()){
      if(!ignoreKeys.contains(key) && source.get(key) == null){
          mapKeysToRemoveSet.add(key);
      }
    }

    source.keySet().removeAll(mapKeysToRemoveSet);

    return source;
  }
}
