from django.contrib import admin
from myapp.models import Post, Comment, Notification

class PostAdmin(admin.ModelAdmin):
    list_display = ('author', 'created_at')

class CommentAdmin(admin.ModelAdmin):
    list_display = ('author', 'created_at', 'post')

class NotificationAdmin(admin.ModelAdmin):
    list_display = ('content', 'created_at', 'receiver', 'is_read')

admin.site.register(Post, PostAdmin)
admin.site.register(Comment, CommentAdmin)
admin.site.register(Notification, NotificationAdmin)
