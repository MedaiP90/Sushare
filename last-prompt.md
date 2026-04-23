in the host prevent guests to connect to closed or deleted tables, if a guest try to connect refuse the connection and in the gust set the session variable `session.status` to `SessionStatus.closed`.

---

TODO:
- participants sync only when dishis are synced, sync them when first connected
