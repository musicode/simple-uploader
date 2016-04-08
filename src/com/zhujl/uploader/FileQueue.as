/**
 * @file 文件队列
 * @author zhujl
 */
package com.zhujl.uploader {

    import flash.events.EventDispatcher;

    import flash.net.FileReference;
    import flash.net.URLRequest;

    public class FileQueue extends EventDispatcher {

        /**
         * 文件队列
         *
         * @type {Array}
         */
        private var files: Array = new Array();

        /**
         * 获得队列中的文件
         *
         * @return {Array}
         */
        public function getFiles(): Array {
            return files;
        }

        /**
         * 设置队列中的文件
         *
         * @param {Array} files 数组元素是 FileReference
         */
        public function setFiles(files: Array): void {
            this.files = files.map(
                function (file: FileReference, index: Number, array: Array): FileItem {
                    return new FileItem(file, index);
                }
            );
        }

    }
}