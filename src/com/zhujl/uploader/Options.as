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
        private var data: Object = { };
        private var headers: Object = {
            'Content-Type': 'multipart/form-data'
        };

        public function Options(options: Object) {
            this.setAccept(options.accept);
            this.setMultiple(options.multiple);
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
        public function getHeaders(): Object {
            return this.headers;
        }

        /**
         * 设置请求头
         *
         * @param {String=} headers
         */
        public function setHeaders(headers: *): void {

            var obj: Object = typeof headers === 'string'
                            ? JSON.decode(headers)
                            : headers;

            Lib.extend(this.headers, obj);
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

    }
}