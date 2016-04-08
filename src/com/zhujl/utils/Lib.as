package com.zhujl.utils {

    import flash.utils.ByteArray;

    public class Lib {

        /**
         * 把 source 混入 target
         *
         * @param {Object} target
         * @param {Object} source1
         * @param {Object?} source2
         * @return {Object}
         */
        public static function extend(target: Object, source1: Object = null, source2: Object = null): Object {
            if (source1) {
                for (var key: String in source1) {
                    if (source1.hasOwnProperty(key)) {
                        target[key] = source1[key]
                    }
                }
            }
            if (source2) {
                for (key in source2) {
                    if (source2.hasOwnProperty(key)) {
                        target[key] = source2[key]
                    }
                }
            }
            return target;
        }
    }
}