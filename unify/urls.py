"""
URL configuration for unify project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from myapp.views import PostViewSet, CommentViewSet, LikePostView
from authentication.views import UserViewSet, ForgotPasswordView, ResetPasswordView, FollowUserView, UnfollowUserView, IsFollowingView
from django.conf import settings
from django.conf.urls.static import static

from rest_framework.routers import SimpleRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

router = SimpleRouter()
router.register('posts', PostViewSet, basename="posts")
router.register('users', UserViewSet, basename='users')
router.register('comments', CommentViewSet, basename='comments')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api-auth/', include('rest_framework.urls')),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot-password'),
    path('reset-password/<int:user_id>/<str:token>/', ResetPasswordView.as_view(), name='reset-password'),
    path('posts/<int:post_id>/like/', LikePostView.as_view(), name='like_post'),
    path("users/<int:user_id>/follow/", FollowUserView.as_view(), name="follow_user"),
    path("users/<int:user_id>/unfollow/", UnfollowUserView.as_view(), name="unfollow_user"),
    path("users/<int:user_id>/is_following/", IsFollowingView.as_view(), name="is_following"),
    path('', include(router.urls)),
]
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
