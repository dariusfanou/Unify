from django.contrib import admin
from myapp.models import Post, Comment, Notification

class PostAdmin(admin.ModelAdmin):
    list_display = ('content', 'created_at', 'author')

class CommentAdmin(admin.ModelAdmin):
    list_display = ('content', 'created_at', 'author', 'post')

class NotificationAdmin(admin.ModelAdmin):
    list_display = ('content', 'created_at', 'receiver', 'is_read')

admin.site.register(Post, PostAdmin)
admin.site.register(Comment, CommentAdmin)
admin.site.register(Notification, NotificationAdmin)
