/**
 * @file 调用外部接口
 * @author zhujl
 */
package com.zhujl.uploader {

    import flash.external.ExternalInterface;
    import flash.events.UncaughtErrorEvent;

    public class ExternalCall {

        private var projectName: String;

        private var movieName: String;

        public function ExternalCall(projectName: String, movieName: String) {
            this.projectName = projectName;
            this.movieName = movieName;
        }

        /**
         * swf 加载完成
         */
        public function ready(): void {
            call('onReady');
        }

        public function fileChange(): void {
            call('onFileChange');
        }

        public function uploadStart(fileItem: FileItem): void {
            call(
                'onUploadStart',
                {
                    fileItem: fileItem.toJsObject()
                }
            );
        }

        public function uploadProgress(fileItem: FileItem, loaded: Number, total: Number): void {
            call(
                'onUploadProgress',
                {
                    fileItem: fileItem.toJsObject(),
                    uploaded: loaded,
                    total: total
                }
            );
        }

        public function uploadSuccess(fileItem: FileItem, responseText: String): void {
            call(
                'onUploadSuccess',
                {
                    fileItem: fileItem.toJsObject(),
                    responseText: responseText
                }
            );
        }

        public function uploadError(fileItem: FileItem, errorCode: Number, errorData: Object = null): void {
            call(
                'onUploadError',
                {
                    fileItem: fileItem.toJsObject(),
                    errorCode: errorCode,
                    errorData: errorData
                }
            );
        }


        public function uploadComplete(fileItem: FileItem): void {
            call(
                'onUploadComplete',
                {
                    fileItem: fileItem.toJsObject()
                }
            );
        }

        public function log(text: String): void {
            call(
                'onLog',
                {
                    text: text
                }
            );
            trace(text);
        }

        public function call(name: String, data: Object = null): void {
            var prefix: String = projectName + '.instances["' + movieName + '"].';
            ExternalInterface.call(prefix + name, data);
        }

        public function addCallback(name: String, fn: Function): void {
            ExternalInterface.addCallback(name, fn);
        }
    }
}