/**
 * @file 入口类
 *
 *       这个项目的初衷是在低版本浏览器中替换 html5 ajax 上传
 *       所以一切功能都参考 html5 来实现，不存在独有特性（没心情写那种东西...）
 *
 *       配置项如下：
 *       {
 *           action: {string} 上传地址
 *           accept: {string=} 允许的文件类型，如 'jpg,jpg'
 *           multiple: {boolean=} 是否可多文件上传
 *           data: {Object=} 附带上传的数据
 *           fileName: {string=} 上传文件的 name 值，默认是 Filedata
 *           header: {Object=} 请求头
 *       }
 * @author zhujl
 */
package com.zhujl.uploader {

    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.UncaughtErrorEvent;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;

    import flash.net.FileReference;
    import flash.net.FileReferenceList;
    import flash.net.FileFilter;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.net.URLRequestHeader;

    import flash.system.Security;

    public class Uploader extends Sprite {

        /**
         * 项目名称
         *
         * 怕重名，给 js 换名字的机会
         *
         * @type {String}
         */
        private var projectName: String;

        /**
         * 当前 swf 名称，当作 ID 用
         *
         * @type {String}
         */
        private var movieName: String;

        /**
         * 点击打开文件选择对话框的按钮
         *
         * @type {Sprite}
         */
        private var button: Sprite;

        /**
         * 外部传入的配置选项
         *
         * @type {Options}
         */
        private var options: Options;

        /**
         * 上传文件队列
         *
         * @type {FileQueue}
         */
        private var queue: FileQueue;

        /**
         * 外部调用
         *
         * @type {ExternalCall}
         */
        private var externalCall: ExternalCall;

        /**
         * 是否禁用
         *
         * @type {Boolean}
         */
        private var isDisable: Boolean;

        /**
         * 貌似不写一个属性，而只是作为临时变量存在，无法触发 SELECT 事件
         */
        private var multipleFiles: FileReferenceList;
        private var singleFile: FileReference;

        public function Uploader() {

            initEnv();
            initButton();
            initOptions();
            initExternal();
            initQueue();
            catchError();
            enable();

            externalCall.ready();
        }

        /**
         * 初始化环境
         */
        private function initEnv(): void {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            Security.allowDomain('*');
            Security.allowInsecureDomain('*');
        }

        /**
         * 初始化按钮
         */
        private function initButton(): void {

            button = new Sprite();

            // 这里不能指定 btn 的大小
            // 因为默认的习惯是让内容撑开容器
            // 如果设置为舞台的大小，因为舞台还没有任何东西，所以高宽为 0
            button.graphics.beginFill(0x000000, 0.2);
            button.graphics.drawRect(0, 0, 200, 200);
            button.graphics.endFill();

            button.buttonMode = true;

            stage.addChild(button);
        }

        /**
         * 初始化配置选项
         */
        private function initOptions(): void {
            var params: Object = stage.loaderInfo.parameters;
/**
            var params:Object = {
                movieName: '_Supload_178245',
                accept: 'mp4,avi,wmv,rm,rmvb,mov,flv',
                multiple: 'false',
                fileName: 'Filedata',
                //data: '{"BAIDUID":"10C34550FCCE3F9B89174192B9AAB169:FG","Hm_lvt_30a9c82538e95ab38df6f182fdcdda66":"1408287428","CNZZDATA1000523207":"365864964-1408287433-|1408287433","Hm_lvt_f4165db5a1ac36eadcfa02a10a6bd243":"1409482227","cflag":"65535:1","H_PS_PSSID":"8406_8533_8689_1449_7802_8234_6727_8679_8488_8056_8559_6504_8503_6018_8592_8625_8578_8729_7798_8167_7963_8448_8737_8436_8458"}',
                projectName: 'Supload'
            };
*/
            this.projectName = params.projectName;
            this.movieName = params.movieName;
            this.options = new Options(params);
        }

        /**
         * 初始化外部通信
         */
        private function initExternal(): void {
            externalCall = new ExternalCall(projectName, movieName);
            externalCall.addCallback('enable', enable);
            externalCall.addCallback('disable', disable);
            externalCall.addCallback('reset', reset);
            externalCall.addCallback('upload', upload);
            externalCall.addCallback('cancel', cancel);
            externalCall.addCallback('getFiles', getFiles);
            externalCall.addCallback('setAction', setAction);
            externalCall.addCallback('setData', setData);
            externalCall.addCallback('dispose', dispose);
        }

        /**
         * 初始化文件队列
         */
        private function initQueue(): void {
            queue = new FileQueue();
        }

        /**
         * 打开文件选择窗口
         */
        private function openFileBrowser(e: MouseEvent): void {

            var fileFilter: FileFilter = new FileFilter('file', options.getAccept());

            if (options.getMultiple()) {
                multipleFiles = new FileReferenceList();
                multipleFiles.addEventListener(Event.SELECT, onFileChange);
                multipleFiles.addEventListener(Event.CANCEL, onFileChange);
                multipleFiles.browse([fileFilter]);
            }
            else {
                singleFile = new FileReference();
                singleFile.addEventListener(Event.SELECT, onFileChange);
                singleFile.addEventListener(Event.CANCEL, onFileChange);
                singleFile.browse([fileFilter]);
            }

            disable();
        }

        /**
         * 启用点击打开文件选择窗口
         */
        public function enable(): void {
            isDisable = false;
            button.useHandCursor = true;
            button.addEventListener(MouseEvent.CLICK, openFileBrowser);
            info('button enabled');
        }

        /**
         * 禁用点击打开文件选择窗口
         */
        public function disable(): void {
            isDisable = true;
            button.useHandCursor = false;
            button.removeEventListener(MouseEvent.CLICK, openFileBrowser);
            info('button disabled');
        }

        /**
         * 重置
         */
        public function reset(): void {

        }

        /**
         * 获得当前队列的文件
         *
         * @return {Array.<Object>}
         */
        public function getFiles(): Array {
            return queue.getFiles().map(
                function (fileItem: FileItem, index: Number, array: Array): Object {
                    return fileItem.toJsObject();
                }
            );
        }

        /**
         * 设置上传地址
         *
         * @param {String} action
         */
        public function setAction(action: String): void {
            options.setAction(action);
            info('setAction: ' + action);
        }

        /**
         * 设置上传数据
         *
         * @param {Object} data 附带一起上传的数据
         */
        public function setData(data: Object): void {
            options.setData(data);
        }

        private function getRequest(): URLRequest {
            var request: URLRequest = new URLRequest(options.getAction());
            request.method = URLRequestMethod.POST;

            var header: Object = options.getHeader();
            if (header) {
                var headers: Array = [];
                for (var key: String in header) {
                    headers.push(
                        new URLRequestHeader(key, header[key])
                    );
                }
                request.requestHeaders = headers;
            }

            var data: Object = options.getData();

            var temp: URLVariables = new URLVariables();
            for (var key: String in data) {
                temp[key] = data[key];
            }
            request.data = temp;

            if (!request.url) {
                error('缺少上传 url');
            }
            return request;
        }

        /**
         * 开始上传
         */
        public function upload(index: uint): void {
            var fileItem: FileItem = queue.getFiles()[index];
            if (fileItem) {
                if (
                    fileItem.upload(
                        getRequest(),
                        options.getFileName()
                    )
                ) {
                    fileItem.addEventListener(FileEvent.UPLOAD_START, onUploadStart);
                    fileItem.addEventListener(FileEvent.UPLOAD_PROGRESS, onUploadProgress);
                    fileItem.addEventListener(FileEvent.UPLOAD_SUCCESS, onUploadSuccess);
                    fileItem.addEventListener(FileEvent.UPLOAD_ERROR, onUploadError);
                    fileItem.addEventListener(FileEvent.UPLOAD_COMPLETE, onUploadComplete);
                }
            }
        }

        /**
         * 中止上传
         */
        public function cancel(index: uint): void {
            var fileItem: FileItem = queue.getFiles()[index];
            if (fileItem) {
                fileItem.cancel();
            }
        }

        /**
         * 销毁对象
         */
        public function dispose(): void {

            queue.getFiles().forEach(
                function (fileItem: FileItem) {
                    fileItem.cancel();
                }
            );

            disable();
            info('dispose');
        }

        public function catchError(): void {
            loaderInfo.uncaughtErrorEvents.addEventListener(
                UncaughtErrorEvent.UNCAUGHT_ERROR,
                function (e: UncaughtErrorEvent) {
                    var err: Error = e.error as Error;
                    error(err.name + ' ' + err.message);
                }
            );
        }

        public function info(text: String): void {
            externalCall.log('[info]' + text);
        }

        public function error(text: String): void {
            externalCall.log('[error]' + text);
        }

        /**
         * 选中文件变化后的事件处理器
         */
        private function onFileChange(e: Event): void {

            info('file change');

            if (singleFile) {
                singleFile.removeEventListener(Event.SELECT, onFileChange);
                singleFile.removeEventListener(Event.CANCEL, onFileChange);

                if (e.type === Event.SELECT) {

                    queue.setFiles([ singleFile ]);
                    externalCall.fileChange();

                    info('fileName: ' + singleFile.name);
                }

                singleFile = null;
            }
            else if (multipleFiles) {
                multipleFiles.removeEventListener(Event.SELECT, onFileChange);
                multipleFiles.removeEventListener(Event.CANCEL, onFileChange);

                if (e.type === Event.SELECT) {

                    queue.setFiles(multipleFiles.fileList);
                    externalCall.fileChange();

                    info('file count: ' + multipleFiles.fileList.length);
                }

                multipleFiles = null;
            }


            enable();


            //setAction('http://220.181.153.135/api/fileupload?offset=0&token=eVp-rEs45SrJ6ekzKFfVt4wWokI5AIfWVaCvcVNN0TdSZlMMOyFxW5QFbK2TCO1mKJeb05MpFJfAEyf1kUNq4_YLmQFvLDmO895LDBAZhRSAZxpW52jV1I3pGOQFC2qGU0XW2R3S9XCcRY463hEsijEjMgxNjDJNd9YTBGjgg_50w0lTi3kKy7vFeVCIRJGKrR9cfcMpJBplV4EfXIWUD-TlOataKrKtLXLsL5R0qQqXdkkuuarAgKH0gLUKwQHpPcwAZXJ_GUjjxc9iQpJjxuA4jojP6hd-tpuLWolmfa-Jrx_OziVY3ACCO2hTeP48T5zosgiALbKR3hAmA6oZo5YAh9Htaim6-0T-bjdJYCP5mMKxO-L96bl3Hq0wGJKE1YlrybLdLKyLxB291lS0HnI6DATaKQtOzWkTOCISF1bol8JvTpr6zxRowUyMEm9rzDaeIGZIKk_AMQe-vDG7fnBDQT7Up5dxlCcYTOoGCa4u_4NgmCIR0TSeWEHUSNIE2SvjCYGT57_5UokM_1fhPccCEtGRY8z3tY2CmK4LVt_lXauYAAc7hUG1QG47Y024Q9nW60pPQFBVwjlnpuXrlpbtMsyyUmMNeSQP4Urzsgw94J4ls25IzPh6ptw~&fmt=cjson');

            // setAction('http://192.168.16.15:9000/cfuupload');
            // upload(1);


        }
        private function onUploadStart(e: FileEvent): void {
            info('uploadStart: ' + e.data.fileItem.file.name);
            externalCall.uploadStart(e.data.fileItem);
        }
        private function onUploadProgress(e: FileEvent): void {
            info('uploadProgress: ' + e.data.loaded + '/' + e.data.total);
            externalCall.uploadProgress(e.data.fileItem, e.data.loaded, e.data.total);
        }
        private function onUploadSuccess(e: FileEvent): void {
            info('uploadSuccess: ' + e.data.responseText);
            externalCall.uploadSuccess(e.data.fileItem, e.data.responseText);
        }
        private function onUploadError(e: FileEvent): void {
            info('uploadError: ' + e.data.errorCode);
            externalCall.uploadError(e.data.fileItem, e.data.errorCode, e.data.errorData);
        }
        private function onUploadComplete(e: FileEvent): void {

            var target: FileItem = e.target as FileItem;
            target.removeEventListener(FileEvent.UPLOAD_START, onUploadStart);
            target.removeEventListener(FileEvent.UPLOAD_PROGRESS, onUploadProgress);
            target.removeEventListener(FileEvent.UPLOAD_SUCCESS, onUploadSuccess);
            target.removeEventListener(FileEvent.UPLOAD_ERROR, onUploadError);
            target.removeEventListener(FileEvent.UPLOAD_COMPLETE, onUploadComplete);

            info('uploadComplete: ' + e.data.fileItem.file.name);
            externalCall.uploadComplete(e.data.fileItem);
        }
    }
}