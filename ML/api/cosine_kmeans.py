"""Spherical K-Means estimator using cosine similarity."""
from __future__ import annotations

import numpy as np
import sys
from sklearn.base import BaseEstimator, ClusterMixin
from sklearn.utils import check_random_state
from sklearn.utils.validation import check_array, check_is_fitted

# Artifacts are trained with ``python train.py`` from ML/api, which records
# this module as ``cosine_kmeans``. Keep that pickle name resolvable when the
# Flask app is imported as ``ML.api.app`` from the repository root as well.
sys.modules.setdefault("cosine_kmeans", sys.modules[__name__])


class SphericalKMeans(ClusterMixin, BaseEstimator):
    """K-Means variant that assigns samples by cosine similarity.

    Samples and centroids are L2-normalized; cluster centers are updated by
    normalizing the mean direction of their assigned samples.
    """

    def __init__(self, n_clusters=8, n_init=10, max_iter=300, tol=1e-4, random_state=None):
        self.n_clusters = n_clusters
        self.n_init = n_init
        self.max_iter = max_iter
        self.tol = tol
        self.random_state = random_state

    @staticmethod
    def _normalize(X):
        norms = np.linalg.norm(X, axis=1, keepdims=True)
        return np.divide(X, norms, out=np.zeros_like(X, dtype=float), where=norms != 0)

    @staticmethod
    def _initialize_centers(X, rng, n_clusters):
        """Cosine-distance-weighted (spherical k-means++) initialization."""
        n_samples = X.shape[0]
        chosen = [int(rng.randint(n_samples))]
        closest_distance = 1.0 - X @ X[chosen[0]]

        while len(chosen) < n_clusters:
            weights = np.maximum(closest_distance, 0.0)
            weights[chosen] = 0.0
            total = weights.sum()
            if total <= np.finfo(float).eps:
                remaining = np.setdiff1d(np.arange(n_samples), chosen, assume_unique=False)
                next_index = int(rng.choice(remaining))
            else:
                next_index = int(rng.choice(n_samples, p=weights / total))
                if next_index in chosen:
                    remaining = np.setdiff1d(np.arange(n_samples), chosen, assume_unique=False)
                    next_index = int(rng.choice(remaining))
            chosen.append(next_index)
            distance = 1.0 - X @ X[next_index]
            closest_distance = np.minimum(closest_distance, distance)

        return X[chosen].copy()

    def fit(self, X, y=None):
        X = check_array(X, dtype=float)
        n_samples, n_features = X.shape
        if not isinstance(self.n_clusters, (int, np.integer)) or self.n_clusters < 1:
            raise ValueError("n_clusters harus berupa bilangan bulat positif.")
        if self.n_clusters > n_samples:
            raise ValueError("n_clusters tidak boleh lebih besar dari jumlah sampel.")
        if self.n_init < 1 or self.max_iter < 1:
            raise ValueError("n_init dan max_iter harus minimal 1.")

        X_unit = self._normalize(X)
        rng = check_random_state(self.random_state)
        best_inertia = np.inf
        best_centers = None
        best_labels = None
        best_n_iter = 0

        for _ in range(self.n_init):
            centers = self._initialize_centers(X_unit, rng, self.n_clusters)
            previous_labels = None

            for iteration in range(1, self.max_iter + 1):
                similarities = X_unit @ centers.T
                labels = np.argmax(similarities, axis=1)
                counts = np.bincount(labels, minlength=self.n_clusters)

                # Move poorly represented samples from non-singleton clusters
                # to empty clusters so all requested clusters remain usable.
                for empty in np.flatnonzero(counts == 0):
                    nearest_similarity = similarities[np.arange(n_samples), labels]
                    candidates = np.argsort(nearest_similarity)
                    donor = next(index for index in candidates if counts[labels[index]] > 1)
                    counts[labels[donor]] -= 1
                    labels[donor] = empty
                    counts[empty] += 1

                updated_centers = np.empty((self.n_clusters, n_features), dtype=float)
                for cluster_id in range(self.n_clusters):
                    direction = X_unit[labels == cluster_id].sum(axis=0)
                    norm = np.linalg.norm(direction)
                    updated_centers[cluster_id] = (
                        direction / norm if norm > 0 else centers[cluster_id]
                    )

                converged = previous_labels is not None and np.array_equal(labels, previous_labels)
                centers = updated_centers
                previous_labels = labels.copy()
                if converged:
                    break

            final_labels = np.argmax(X_unit @ centers.T, axis=1)
            final_similarity = (X_unit * centers[final_labels]).sum(axis=1)
            inertia = float(np.sum(1.0 - final_similarity))
            if inertia < best_inertia:
                best_inertia = inertia
                best_centers = centers.copy()
                best_labels = final_labels.copy()
                best_n_iter = iteration

        self.cluster_centers_ = best_centers
        self.labels_ = best_labels
        self.inertia_ = best_inertia
        self.n_iter_ = best_n_iter
        self.n_features_in_ = n_features
        return self

    def predict(self, X):
        check_is_fitted(self, attributes=["cluster_centers_"])
        X = check_array(X, dtype=float)
        if X.shape[1] != self.n_features_in_:
            raise ValueError(
                f"X memiliki {X.shape[1]} fitur, sedangkan model dilatih dengan "
                f"{self.n_features_in_} fitur."
            )
        return np.argmax(self._normalize(X) @ self.cluster_centers_.T, axis=1)