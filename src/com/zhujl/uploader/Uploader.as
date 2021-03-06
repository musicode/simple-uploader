﻿/**
 * @file 入口类
 *
 *       这个项目的初衷是在低版本浏览器中替换 html5 ajax 上传
 *       所以一切功能都参考 html5 来实现，不存在独有特性（没心情写那种东西...）
 *
 *       配置项如下：
 *       {
 *           accept: {string=} 允许的文件类型，如 'jpg,jpg'
 *           multiple: {boolean=} 是否可多文件上传
 *       }
 *
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

    import com.zhujl.utils.Lib;

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

            // var params:Object = {
            //     projectName: 'Supload',
            //     movieName: '_Supload_178245',
            //     accept: 'mp4,avi,wmv,rm,rmvb,mov,flv',
            //     multiple: 'false'
            // };

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
            externalCall.addCallback('upload', upload);
            externalCall.addCallback('abort', abort);
            externalCall.addCallback('getFiles', getFiles);
            externalCall.addCallback('destroy', destroy);
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

        private function getRequest(action: String, data: Object, headers: Object): URLRequest {

            var request: URLRequest = new URLRequest(action);
            request.method = URLRequestMethod.POST;

            if (data) {
                var variables: URLVariables = new URLVariables();
                for (var key: String in data) {
                    variables[key] = data[key];
                }
                request.data = variables;
            }

            var allHeaders = {
                'Content-Type': 'multipart/form-data'
            }
            if (headers) {
                Lib.extend(allHeaders, headers)
            }

            var requestHeaders: Array = [];
            for (var name: String in allHeaders) {
                requestHeaders.push(
                    new URLRequestHeader(name, allHeaders[name])
                );
            }
            request.requestHeaders = requestHeaders;

            return request;

        }

        /**
         * 开始上传
         */
        public function upload(index: uint, action: String, fileName: String, data: Object, headers: Object): void {
            var fileItem: FileItem = queue.getFiles()[index];
            if (fileItem) {
                if (fileItem.upload(getRequest(action, data, headers), fileName)) {
                    fileItem.addEventListener(FileEvent.UPLOAD_START, onUploadStart);
                    fileItem.addEventListener(FileEvent.UPLOAD_PROGRESS, onUploadProgress);
                    fileItem.addEventListener(FileEvent.UPLOAD_SUCCESS, onUploadSuccess);
                    fileItem.addEventListener(FileEvent.UPLOAD_ERROR, onUploadError);
                    fileItem.addEventListener(FileEvent.UPLOAD_ABORT, onUploadAbort);
                    fileItem.addEventListener(FileEvent.UPLOAD_END, onUploadEnd);
                }
            }
        }

        /**
         * 中止上传
         */
        public function abort(index: uint): void {
            var fileItem: FileItem = queue.getFiles()[index];
            if (fileItem) {
                fileItem.abort();
            }
        }

        /**
         * 销毁对象
         */
        public function destroy(): void {

            queue.getFiles().forEach(
                function (fileItem: FileItem) {
                    fileItem.abort();
                }
            );

            disable();
            info('destroy');
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

            if (singleFile) {
                singleFile.removeEventListener(Event.SELECT, onFileChange);
                singleFile.removeEventListener(Event.CANCEL, onFileChange);

                if (e.type === Event.SELECT) {
                    queue.setFiles([ singleFile ]);
                    externalCall.fileChange();

                    info('select file: ' + singleFile.name);
                }
                else {
                  info('cancel file');
                }

                singleFile = null;
            }
            else if (multipleFiles) {
                multipleFiles.removeEventListener(Event.SELECT, onFileChange);
                multipleFiles.removeEventListener(Event.CANCEL, onFileChange);

                if (e.type === Event.SELECT) {
                    queue.setFiles(multipleFiles.fileList);
                    externalCall.fileChange();

                    info('select file count: ' + multipleFiles.fileList.length);
                }
                else {
                  info('cancel file');
                }

                multipleFiles = null;
            }

            enable();

        }
        private function onUploadStart(e: FileEvent): void {
            info('upload start: ' + e.data.fileItem.index);
            externalCall.uploadStart(e.data.fileItem);
        }
        private function onUploadProgress(e: FileEvent): void {
            info('upload progress: ' + e.data.fileItem.index + ' ' + e.data.loaded + '/' + e.data.total);
            externalCall.uploadProgress(e.data.fileItem, e.data.loaded, e.data.total);
        }
        private function onUploadSuccess(e: FileEvent): void {
            info('upload success: ' + e.data.fileItem.index + ' ' + e.data.responseText);
            externalCall.uploadSuccess(e.data.fileItem, e.data.responseText);
        }
        private function onUploadError(e: FileEvent): void {
            info('upload error: ' + e.data.fileItem.index + ' ' + e.data.errorCode);
            externalCall.uploadError(e.data.fileItem, e.data.errorCode, e.data.errorData);
        }
        private function onUploadAbort(e: FileEvent): void {
            info('upload abort: ' + e.data.fileItem.index);
            externalCall.uploadAbort(e.data.fileItem);
        }
        private function onUploadEnd(e: FileEvent): void {

            var target: FileItem = e.target as FileItem;
            target.removeEventListener(FileEvent.UPLOAD_START, onUploadStart);
            target.removeEventListener(FileEvent.UPLOAD_PROGRESS, onUploadProgress);
            target.removeEventListener(FileEvent.UPLOAD_SUCCESS, onUploadSuccess);
            target.removeEventListener(FileEvent.UPLOAD_ERROR, onUploadError);
            target.removeEventListener(FileEvent.UPLOAD_ABORT, onUploadAbort);
            target.removeEventListener(FileEvent.UPLOAD_END, onUploadEnd);

            info('upload end: ' + e.data.fileItem.index);
            externalCall.uploadEnd(e.data.fileItem);
        }
    }
}