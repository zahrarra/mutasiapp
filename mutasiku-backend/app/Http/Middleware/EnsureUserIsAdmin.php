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

        if (! $user || $user->role?->name !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Hanya role admin yang diizinkan mengakses resource ini.',
            ], 403);
        }

        return $next($request);
    }
}
