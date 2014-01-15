(function(){
    var Ext = window.Ext4 || window.Ext;

    Ext.define('Rally.apps.iterationtrackingboard.IsLeafHelper', {
        singleton: true,
        isLeaf: function(record) {
            if (!record.parentNode) {
                return false;
            }

            return  (!record.raw.Tasks || record.raw.Tasks.Count === 0) &&
                    (!record.raw.Defects || record.raw.Defects.Count === 0) &&
                    (record.raw._type === 'TestSet' || !record.raw.TestCases || record.raw.TestCases.Count === 0); //remove the type check once TestCases under TestSets can be queried through the artifact endpoint
        }
    });
})();