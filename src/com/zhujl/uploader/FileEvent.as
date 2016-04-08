/**
 * @file 文件事件
 * @author zhujl
 */
package com.zhujl.uploader {

    import flash.events.Event;
    import flash.net.FileReference;

    public class FileEvent extends Event {

        /**
         * 选择文件发生变化事件
         *
         * @const
         * @type {String}
         */
        public static const FILE_CHANGE: String = 'fileChange';

        /**
         * 文件开始上传事件
         *
         * @const
         * @type {String}
         */
        public static const UPLOAD_START: String = 'uploadStart';

        /**
         * 文件正在上传事件
         *
         * @const
         * @type {String}
         */
        public static const UPLOAD_PROGRESS: String = 'uploadProgress';

        /**
         * 文件上传成功事件
         *
         * @const
         * @type {String}
         */
        public static const UPLOAD_SUCCESS: String = 'uploadSuccess';

        /**
         * 文件上传失败事件
         *
         * @const
         * @type {String}
         */
        public static const UPLOAD_ERROR: String = 'uploadError';

        /**
         * 文件上传完成事件
         *
         * @const
         * @type {String}
         */
        public static const UPLOAD_COMPLETE: String = 'uploadComplete';

        /**
         * 用于事件广播时传递数据
         *
         * @type {Object}
         */
        public var data: Object;

        public function FileEvent(type: String,
                                    data: Object = null,
                                    bubbles: Boolean = false,
                                    cancelable: Boolean = false) {
            super(type, bubbles, cancelable);
            this.data = data;
        }

        public override function clone(): Event {
            return new FileEvent(type, data, bubbles, cancelable);
        }
    }
}