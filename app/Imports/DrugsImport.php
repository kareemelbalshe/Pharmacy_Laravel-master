<?php

namespace App\Imports;

use App\Models\Drug;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class DrugsImport implements ToCollection, WithHeadingRow
{
    /**
     * @param Collection $rows
     */
    public function collection(Collection $rows)
    {
        \Illuminate\Support\Facades\Log::info('DrugsImport collection count: ' . $rows->count());
        if ($rows->isNotEmpty()) {
            \Illuminate\Support\Facades\Log::info('First row keys: ' . json_encode(array_keys($rows->first()->toArray())));
            \Illuminate\Support\Facades\Log::info('First row data: ' . json_encode($rows->first()->toArray()));
        }

        foreach ($rows as $row) {
            // Resolve column headers dynamically to support various naming styles
            $nameEn   = $row['name_en'] ?? $row['name_eng'] ?? null;
            $nameAr   = $row['name_ar'] ?? $row['name_ara'] ?? null;
            $imageUrl = $row['image_url'] ?? $row['image'] ?? null;
            $price    = $row['price'] ?? 0.0;

            // Skip rows without an English name to avoid invalid entries
            if (empty($nameEn)) {
                continue;
            }

            Drug::updateOrCreate(
                ['name_en' => $nameEn],
                [
                    'name_ar'   => $nameAr,
                    'image_url' => $imageUrl,
                    'price'     => $price,
                ]
            );
        }
    }
}
