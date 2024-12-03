python finetune.py


python finetune.py --json_file fashion_ai_data/captioned_data/men_accessories/2024-11-18_11-34-54/men_accessories.json --image_dir fashion_ai_data/scrapped_data/men_accessories/2024-11-18_11-34-54 --project men_accessories_fine_tuned_fashionclip --prefix men_accessories --checkpoint men_clothes_fine_tuned_fashionclip



python finetune.py --json_file fashion_ai_data/captioned_data/men_shoes/2024-11-18_11-34-54/men_shoes.json --image_dir fashion_ai_data/scrapped_data/men_shoes/2024-11-18_11-34-54 --project men_shoes_fine_tuned_fashionclip --prefix men_shoes --checkpoint men_accessories_fine_tuned_fashionclip



python finetune.py --json_file fashion_ai_data/captioned_data/women_accessories/2024-11-18_11-34-54/women_accessories.json --image_dir fashion_ai_data/scrapped_data/women_accessories/2024-11-18_11-34-54 --project women_accessories_fine_tuned_fashionclip --prefix women_accessories --checkpoint men_shoes_fine_tuned_fashionclip



python finetune.py --json_file fashion_ai_data/captioned_data/women_clothes/2024-11-18_11-34-54/women_clothes.json --image_dir fashion_ai_data/scrapped_data/women_clothes/2024-11-18_11-34-54 --project women_clothes_fine_tuned_fashionclip --prefix women_clothes --checkpoint women_accessories_fine_tuned_fashionclip



python finetune.py --json_file fashion_ai_data/captioned_data/women_shoes/2024-11-18_11-34-54/women_shoes.json --image_dir fashion_ai_data/scrapped_data/women_shoes/2024-11-18_11-34-54 --project women_shoes_fine_tuned_fashionclip --prefix women_shoes --checkpoint women_clothes_fine_tuned_fashionclip

