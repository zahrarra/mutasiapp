<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsAdmin
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user()?->loadMissing('role');
        $roleName = $user?->role?->name;

        // Bagian Aset diizinkan membaca master user untuk penetapan PIC baru (PRD V1.1 §6.4)
        $isBagianAsetReadUsers = $request->isMethod('GET')
            && $roleName === 'bagian_aset'
            && ($request->is('api/v1/admin/users') || $request->is('api/v1/admin/users/*'));

        if (! $user || ($roleName !== 'admin' && ! $isBagianAsetReadUsers)) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Hanya role admin yang diizinkan mengakses resource ini.',
            ], 403);
        }

        return $next($request);
    }
}
