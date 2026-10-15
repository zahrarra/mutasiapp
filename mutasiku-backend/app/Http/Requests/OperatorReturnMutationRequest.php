<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class OperatorReturnMutationRequest extends FormRequest
{
    /**
     * Operator tidak memiliki kewenangan untuk mengembalikan pengajuan mutasi.
     */
    public function authorize(): bool
    {
        return false;
    }

    public function rules(): array
    {
        return [];
    }
}
