/**
 * @file 队列中的文件项
 * @author zhujl
 */
package com.zhujl.uploader {

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.DataEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.IOErrorEvent;
    import flash.events.HTTPStatusEvent;
    import flash.events.TimerEvent;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.LoaderInfo;

    import flash.geom.Rectangle;

    import flash.net.FileReference;
    import flash.net.URLRequest;

    import flash.utils.ByteArray;
    import flash.utils.Timer;

    public class FileItem extends EventDispatcher {

        /**
         * 等待上传状态
         *
         * @const
         * @type {Number}
         */
        public static const STATUS_WAITING: Number = 0;

        /**
         * 上传中状态
         *
         * @const
         * @type {Number}
         */
        public static const STATUS_UPLOADING: Number = 1;

        /**
         * 上传成功状态
         *
         * @const
         * @type {Number}
         */
        public static const STATUS_UPLOAD_SUCCESS: Number = 2;

        /**
         * 上传失败状态
         *
         * @const
         * @type {Number}
         */
        public static const STATUS_UPLOAD_ERROR: Number = 3;

        /**
         * 上传中止错误
         *
         * @const
         * @type {Number}
         */
        public static const ERROR_CANCEL: Number = 0;

        /**
         * 上传出现沙箱安全错误
         *
         * @const
         * @type {Number}
         */
        public static const ERROR_SECURITY: Number = 1;

        /**
         * 上传 IO 错误
         *
         * @const
         * @type {Number}
         */
        public static const ERROR_IO: Number = 2;

        /**
         * 文件在队列中的索引
         *
         * @type {Number}
         */
        public var index: Number;

        /**
         * 文件当前状态
         *
         * @type {Number}
         */
        public var status: Number;

        /**
         * 文件对象
         *
         * @type {FileReference}
         */
        public var file: FileReference;

        /**
         * 用于临时存储 http 错误状态码
         *
         * @type {Number}
         */
        private var httpStatus: Number;

        /**
         * 上传成功之后等待 DataEvent.UPLOAD_COMPLETE_DATA 触发的定时器
         *
         * @type {Timer}
         */
        private var dataTimer: Timer;


        public function FileItem(file: FileReference, index: Number) {
            this.file = file;
            this.index = index;
            this.status = FileItem.STATUS_WAITING;
        }

        /**
         * 上传文件
         *
         * @param {URLRequest} request
         * @param {string} fileName
         * @return {Boolean}
         */
        public function upload(request: URLRequest, fileName: String): Boolean {
            if (status === FileItem.STATUS_WAITING) {
                file.addEventListener(Event.OPEN, onUploadStart);
                file.addEventListener(ProgressEvent.PROGRESS, onUploadProgress);
                file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onUploadSuccess);
                file.addEventListener(Event.COMPLETE, onUploadComplete);

                file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onUploadSecurityError);
                file.addEventListener(HTTPStatusEvent.HTTP_STATUS, onUploadHttpStatus);
                file.addEventListener(IOErrorEvent.IO_ERROR, onUploadIOError);

                file.upload(request, fileName, false);
                return true;
            }
            return false;
        }

        /**
         * 停止上传文件
         *
         * @return {Boolean}
         */
        public function cancel(): Boolean {
            if (status === FileItem.STATUS_UPLOADING) {
                file.cancel();
                uploadError(FileItem.ERROR_CANCEL);
                return true;
            }
            return false;
        }

        /**
         * 转成 js 对象
         * 如果把 as 对象扔给 js，会报安全错误
         *
         * @return {Object}
         */
        public function toJsObject(): Object {
            var type = getFileType();
            return {
                index: index,
                status: status,
                file: {
                    name: file.name,
                    type: type.length > 0 ? type.substr(1).toLowerCase() : type,
                    size: file.size
                },
                nativeFile: {
                    creationDate: file.creationDate.getTime(),
                    creator: file.creator || '',
                    modificationDate: file.modificationDate.getTime(),
                    name: file.name,
                    size: file.size,
                    type: type
                }
            };
        }

        /**
         * Mac OS 偶尔不能正常获得 type
         *
         * @return {String}
         */
        private function getFileType(): String {
            var type: String = file.type;
            if (!type) {
                var index: Number = file.name.lastIndexOf('.');
                if (index >= 0) {
                    type = file.name.substr(index);
                }
            }
            return type ? type.toLowerCase() : '';
        }

        /**
         * 开始上传触发
         */
        private function onUploadStart(e: Event): void {
            status = FileItem.STATUS_UPLOADING;

            dispatchFileEvent(
                FileEvent.UPLOAD_START,
                {
                    fileItem: this
                }
            );
        }

        /**
         * 正在上传触发
         */
        private function onUploadProgress(e: ProgressEvent): void {
            dispatchFileEvent(
                FileEvent.UPLOAD_PROGRESS,
                {
                    fileItem: this,
                    loaded: e.bytesLoaded,
                    total: e.bytesTotal
                }
            );
        }

        /**
         * 服务器返回 200 状态码触发
         */
        private function onUploadComplete(e: Event): void {
            // DataEvent.UPLOAD_COMPLETE_DATA 在 Event.COMPLETE 之后触发
            dataTimer = new Timer(100, 1);
            dataTimer.addEventListener(TimerEvent.TIMER, onDataTimer);
            dataTimer.start();
        }

        /**
         * 从服务器接受到数据触发
         */
        private function onUploadSuccess(e: DataEvent): void {
            if (dataTimer) {
                dataTimer.stop();
                dataTimer = null;
            }
            uploadSuccess(e.data);
        }

        private function onDataTimer(e: TimerEvent): void {
            if (dataTimer) {
                dataTimer.stop();
                dataTimer = null;
            }
            uploadSuccess();
        }

        /**
         * 出现安全沙箱问题触发
         */
        private function onUploadSecurityError(e: SecurityErrorEvent): void {
            uploadError(FileItem.ERROR_SECURITY);
        }

        /**
         * 上传失败并且存在可描述失败的状态码，之后会触发 ioError
         */
        private function onUploadHttpStatus(e: HTTPStatusEvent): void {
            httpStatus = e.status;
        }

        /**
         * IO 错误
         */
        private function onUploadIOError(e: IOErrorEvent): void {
            var data: Object = {
                text: e.text
            };

            if (httpStatus) {
                data.status = httpStatus;
            }

            uploadError(FileItem.ERROR_IO, data);
        }

        private function uploadSuccess(responseText: String = ''): void {
            status = FileItem.STATUS_UPLOAD_SUCCESS;
            dispatchFileEvent(
                FileEvent.UPLOAD_SUCCESS,
                {
                    fileItem: this,
                    responseText: responseText
                }
            );
            uploadComplete();
        }
        private function uploadError(errorCode: Number, errorData: Object = null): void {
            status = FileItem.STATUS_UPLOAD_ERROR;
            dispatchFileEvent(
                FileEvent.UPLOAD_ERROR,
                {
                    fileItem: this,
                    errorCode: errorCode,
                    errorData: errorData
                }
            );
            uploadComplete();
        }

        /**
         * 上传成功或失败之后调用
         */
        private function uploadComplete(): void {
            file.removeEventListener(Event.OPEN, onUploadStart);
            file.removeEventListener(ProgressEvent.PROGRESS, onUploadProgress);
            file.removeEventListener(Event.COMPLETE, onUploadComplete);
            file.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onUploadSuccess);

            file.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onUploadSecurityError);
            file.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onUploadHttpStatus);
            file.removeEventListener(IOErrorEvent.IO_ERROR, onUploadIOError);

            dispatchFileEvent(
                FileEvent.UPLOAD_COMPLETE,
                {
                    fileItem: this
                }
            );
        }

        /**
         * 给 FileEvent 设置一个统一分发出口
         *
         * @param {String} type 事件名称
         * @param {Object} data 事件数据
         */
        private function dispatchFileEvent(type: String, data: Object): void {
            var e: FileEvent = new FileEvent(type, data);
            dispatchEvent(e);
        }
    }
}