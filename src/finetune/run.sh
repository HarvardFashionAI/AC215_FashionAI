python finetune.py --json_file fashion_ai_data/captioned_data/men_accessories/2024-11-18_11-34-54/men_accessories.json --image_dir fashion_ai_data/scrapped_data/men_accessories/2024-11-18_11-34-54 --project men_accessories_fine_tuned_fashionclip --prefix men_accessories --checkpoint men_clothes_fine_tuned_fashionclip



python finetune.py --json_file fashion_ai_data/captioned_data/men_shoes/2024-11-18_11-34-54/men_shoes.json --image_dir fashion_ai_data/scrapped_data/men_shoes/2024-11-18_11-34-54 --project men_shoes_fine_tuned_fashionclip --prefix men_shoes --checkpoint men_accessories_fine_tuned_fashionclip



