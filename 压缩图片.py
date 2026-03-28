import os
from PIL import Image

def compress_large_images(target_dir, max_size_mb=10, quality=80):
    """
    遍历指定目录，将大于 max_size_mb 的图片压缩并转换为 WebP 格式。
    """
    # 将 MB 转换为 Bytes
    max_size_bytes = max_size_mb * 1024 * 1024 
    
    # 检查目录是否存在
    if not os.path.exists(target_dir):
        print(f"❌ 找不到目录: {target_dir}")
        return

    print(f"🔍 正在扫描: {target_dir} (寻找大于 {max_size_mb}MB 的图片)...")
    
    for root, _, files in os.walk(target_dir):
        for file in files:
            file_path = os.path.join(root, file)
            
            # 只处理常见的图片格式
            if not file.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp')):
                continue
                
            file_size = os.path.getsize(file_path)
            
            if file_size > max_size_bytes:
                print(f"📦 发现大文件: {file} ({file_size / (1024*1024):.2f} MB)")
                
                try:
                    with Image.open(file_path) as img:
                        # 如果是 RGBA (带透明通道) 的 PNG，转换为 RGB 避免一些兼容问题
                        if img.mode in ("RGBA", "P"):
                            img = img.convert("RGB")
                        
                        # 构建新的文件名 (替换为 .webp)
                        file_name_without_ext = os.path.splitext(file)[0]
                        new_file_path = os.path.join(root, f"{file_name_without_ext}.webp")
                        
                        # 保存为 webp 格式
                        img.save(new_file_path, "WEBP", quality=quality)
                        
                        new_size = os.path.getsize(new_file_path)
                        print(f"   ✅ 压缩完成: 保存为 .webp ({new_size / (1024*1024):.2f} MB)")
                        
                        # 压缩成功后，可选择删除原图 (取消下面这行的注释即可)
                        os.remove(file_path) 
                        
                except Exception as e:
                    print(f"   ❌ 处理 {file} 时出错: {e}")

if __name__ == "__main__":
    # 填入你博客存放这次作业图片的绝对或相对路径
    image_directory = "assets/img/posts/20260328-hw2/image" 
    
    # 运行压缩 (默认寻找大于 10MB 的图片，以 80% 质量保存)
    compress_large_images(image_directory, max_size_mb=10, quality=80)