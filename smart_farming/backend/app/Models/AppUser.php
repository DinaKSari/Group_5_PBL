<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AppUser extends Model
{
    protected $fillable = [
        'uid',
        'email',
        'name',
    ];

    public function predictions(): HasMany
    {
        return $this->hasMany(Prediction::class, 'user_uid', 'uid');
    }

    /** Label manusiawi untuk panel admin: nama, lalu email, lalu UID pendek. */
    public function getLabelAttribute(): string
    {
        if (!empty($this->name)) {
            return $this->name;
        }
        if (!empty($this->email)) {
            return $this->email;
        }
        return substr((string) $this->uid, 0, 10).'…';
    }
}
