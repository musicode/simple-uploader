/**
 * @file 前端传给 flash 的配置
 * @author zhujl
 */
package com.zhujl.uploader {

    import com.adobe.serialization.json.JSON;
    import com.zhujl.utils.Lib;

    public class Options {

        private var action: String;
        private var accept: String;
        private var multiple: Boolean;
        private var fileName: String;
        private var ignoreError: Boolean;
        private var data: Object = { };
        private var header: Object = {
            'Content-Type': 'multipart/form-data'
        };

        public function Options(options: Object) {
            this.setAction(options.action);
            this.setAccept(options.accept);
            this.setMultiple(options.multiple);
            this.setFileName(options.fileName);
            this.setIgnoreError(options.ignoreError);
            this.setData(options.data);
            this.setHeader(options.header);
        }

        /**
         * 获取上传地址
         *
         * @return {String}
         */
        public function getAction(): String {
            return this.action;
        }

        /**
         * 设置上传地址
         *
         * @params {String=}
         */
        public function setAction(action: String = ''): void {
            this.action = action;
        }

        /**
         * 获取允许上传的文件格式
         *
         * @return {String}
         */
        public function getAccept(): String {
            return this.accept;
        }

        /**
         * 设置允许上传的文件格式
         *
         * @param {String=} accept 如 'jpg,png'
         */
        public function setAccept(accept: String = ''): void {

            if (accept) {
                accept = accept.split(',')
                               .map(function (ext: String, index: Number, array: Array) {
                                   return '*.' + ext;
                               })
                               .join(';');
            }
            else {
                accept = '*.*';
            }

            this.accept = accept;
        }

        /**
         * 获取是否可以多文件上传
         *
         * @return {Boolean}
         */
        public function getMultiple(): Boolean {
            return this.multiple;
        }

        /**
         * 设置是否可以多文件上传
         *
         * @param {*=} multiple
         */
        public function setMultiple(multiple: *): void {
            switch (typeof multiple) {
                case 'boolean':
                    this.multiple = multiple;
                    break;
                case 'string':
                    this.multiple = multiple === 'true' ? true : false;
                    break
                default:
                    this.multiple = false;
                    break;
            }
        }

        /**
         * 获取上传数据
         *
         * @return {Object}
         */
        public function getData(): Object {
            return this.data;
        }

        /**
         * 设置上传数据
         *
         * @param {String=} data
         */
        public function setData(data: *): void {

            var obj: Object = typeof data === 'string'
                            ? JSON.decode(data)
                            : data;

            Lib.extend(this.data, obj);

        }

        /**
         * 获取请求头
         *
         * @return {Object}
         */
        public function getHeader(): Object {
            return this.header;
        }

        /**
         * 设置请求头
         *
         * @param {String=} header
         */
        public function setHeader(header: *): void {

            var obj: Object = typeof header === 'string'
                            ? JSON.decode(header)
                            : header;

            Lib.extend(this.header, obj);
        }

        /**
         * 获取上传文件 name
         *
         * @return {String}
         */
        public function getFileName(): String {
            return this.fileName;
        }

        /**
         * 设置上传文件 name
         *
         * @param {String=} fileName
         */
        public function setFileName(fileName: String = null): void {
            this.fileName = typeof fileName === 'string'
                          ? fileName
                          : 'Filedata';
        }

        /**
         * 多文件上传时，是否忽略错误继续上传
         *
         * @return {Boolean}
         */
        public function getIgnoreError(): Boolean {
            return this.ignoreError;
        }

        /**
         * 多文件上传时，是否忽略错误继续上传
         *
         * @param {Boolean} ignoreError
         */
        public function setIgnoreError(ignoreError: *): void {
            switch (typeof ignoreError) {
                case 'boolean':
                    this.ignoreError = ignoreError;
                    break;
                case 'string':
                    this.ignoreError = ignoreError === 'true' ? true : false;
                    break
                default:
                    this.ignoreError = false;
                    break;
            }
        }
    }
}