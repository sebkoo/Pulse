package com.pulse.core

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** What a module card can be showing at any moment — the Kotlin mirror of the
 *  Swift `ModulePhase` enum, as a sealed hierarchy. */
sealed interface ModulePhase<out T> {
    data object Loading : ModulePhase<Nothing>
    data class Loaded<T>(val result: ProviderResult<T>) : ModulePhase<T>
    data class Failed(val message: String) : ModulePhase<Nothing>
}

/**
 * View-model for one dashboard module. Generic over the provider, so every
 * module gets identical semantics: load → fresh, or cached-marked-stale, or a
 * readable failure. The UI just collects [phase].
 *
 * `StateFlow` is Kotlin's Observation: the view observes it, the model owns it.
 */
class ModuleModel<T>(
    private val provider: DataProvider<T>,
    private val cache: PayloadCache<T>,
) {
    private val _phase = MutableStateFlow<ModulePhase<T>>(ModulePhase.Loading)
    val phase: StateFlow<ModulePhase<T>> = _phase.asStateFlow()

    suspend fun load(now: Long) {
        _phase.value = try {
            ModulePhase.Loaded(provider.fetchCachingLastGood(cache, now))
        } catch (_: Exception) {
            ModulePhase.Failed("Couldn't load ${provider.title.lowercase()}. Pull to retry.")
        }
    }
}
