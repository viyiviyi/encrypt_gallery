# [加密相册](https://github.com/viyiviyi/encrypt_gallery)

---

这个软件提供浏览*加密或未加密*图片的功能，且支持对整个目录的图片进行加密、解密，同时可以查看图片的附加参数（比如sd-webui生成参数）。

作为相册软件时，功能并不完善，只提供**目录浏览**、**查看大图**、**裁剪**、**单张移动**、**删除**的功能。

#### 这个软件的主要目的是浏览、解密、加密以下项目产生或需求的图片：
- [stable-diffusion-webui 图片加密插件](https://github.com/viyiviyi/sd-encrypt-image) 
- [ConfyUI 图片加密插件](https://github.com/viyiviyi/comfyui-encrypt-image)

#### 备注
- 如果在解密以上插件生成的图片时，如果在软件内查看时图片没有解密，请检查密码是否出错。
- 解密速度和设备性能有关，开始解密后将会后台进行。
- 如果解密目标目录存在同名文件，会自动跳过。
- 主要功能差不多完成了，求个赞助。[爱发电主页](https://afdian.net/a/yiyiooo)


#### 使用场景：
1. 将图片加密后作为数据集上传到kaggle，可以解决训练模型时数据集有nsfw图片导致封号的问题，需要配合[解密读取图片](https://github.com/viyiviyi/encrypt_image_script)的代码使用。
2. 对kaggle运行stable-diffusion-webui或ConfyUI并开启加密插件后，浏览和解密打包下载的图片。
3. 加密保存手机、电脑上的图片，并通过软件进行查看。


下载地址：
[https://github.com/viyiviyi/encrypt_gallery/releases](https://github.com/viyiviyi/encrypt_gallery/releases)
