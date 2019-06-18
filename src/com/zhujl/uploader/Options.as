/**
 * @file 前端传给 flash 的配置
 * @author zhujl
 */
package com.zhujl.uploader {

    public class Options {

        private var accept: String;
        private var multiple: Boolean;

        public function Options(options: Object) {
            this.setAccept(options.accept);
            this.setMultiple(options.multiple);
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

    }
}