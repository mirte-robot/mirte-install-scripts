

# # write a img file to emmc/nvme/sdcard
#     source_location = ""
#     # if config has image_file, then use that file to install
#     if configuration.get("image_file", "") != "":
#         image_file = configuration["image_file"]
#         if not os.path.isfile(image_file):
#             print(f"Image file {image_file} does not exist, skipping installation")
#             return
#         print(f"Installing image {image_file} to {target_dev}, this may take a while...")
#         source_location = image_file